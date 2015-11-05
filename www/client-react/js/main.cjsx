React = require 'react'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v
$ = require 'jquery'

renderMarkdown = (str) ->
  __html: markdown.toHTML str

NoteView = React.createClass
  render: ->
    <div>
      <p><button type="button" onClick={@props.onBack}>Back</button></p>
      <p><img src={@props.note.photo_url} /></p>
      <p>{@props.note.description}</p>
      { for comment in @props.note.comments
          <div key={"comment-#{comment.comment_id}"}>
            <h4>{comment.user.display_name}, {comment.created.toLocaleString()}</h4>
            <p>{comment.description}</p>
          </div>
      }
    </div>

SearchBox = React.createClass
  handleChange: ->
    tags =
      tag for tag in @props.tags when @refs["searchTag#{tag.tag_id}"].getDOMNode().checked
    text = @refs.searchText.getDOMNode().value
    @props.onSearch tags, text

  render: ->
    <form>
      { for tag in @props.tags
          <p key={tag.tag_id}>
            <label>
              <input type="checkbox"
                ref="searchTag#{tag.tag_id}"
                checked={tag in @props.checkedTags}
                onChange={@handleChange}
              />
              { tag.tag }
            </label>
          </p>
      }
      <p>
        <input type="text" ref="searchText" value={@props.searchText} onChange={@handleChange} />
      </p>
    </form>

App = React.createClass
  getInitialState: ->
    notes: []
    viewing: null
    searching: false
    checkedTags: []
    searchText: ''
    latitude: @props.game.latitude
    longitude: @props.game.longitude
    zoom: @props.game.zoom
    auth: null
    username: ''
    password: ''

  componentDidMount: ->
    @login undefined, undefined
    window.addEventListener 'hashchange', => @applyHash()

  login: (username, password) ->
    @props.aris.login username, password, => @updateLogin()

  logout: ->
    window.location.hash = '#'
    @props.aris.logout()
    @updateLogin()

  updateLogin: ->
    @setState auth: @props.aris.auth
    @handleSearch undefined, undefined, false

  applyHash: (notes) ->
    hash = window.location.hash[1..]
    note_id = parseInt hash
    matchingNotes =
      note for note in notes ? @state.notes when note.note_id is note_id
    if matchingNotes.length is 1
      @setState viewing: matchingNotes[0]
    else
      @setState viewing: null

  handleMapChange: ([lat, lng], zoom, bounds, marginBounds) ->
    @setState
      latitude: lat
      longitude: lng
      zoom: zoom

  render: ->
    <div>
      { if @state.auth?
          <div>
            <p><code>{ JSON.stringify @state.auth }</code></p>
            <p><button type="button" onClick={@logout}>Logout</button></p>
          </div>
        else
          <form>
            <p>
              <input type="text" placeholder="Username" value={@state.username} onChange={(e) => @setState username: e.target.value} />
            </p>
            <p>
              <input type="password" placeholder="Password" value={@state.password} onChange={(e) => @setState password: e.target.value} />
            </p>
            <p>
              <button type="submit" onClick={(e) => e.preventDefault(); @login(@state.username, @state.password)}>Login</button>
            </p>
          </form>
      }
      <h1>{ @props.game.name }</h1>
      <h2>A Siftr by { (u.display_name for u in @props.game.owners).join(', ') }</h2>
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} />
      <div style={width: '500px', height: '500px'}>
        <NoteMap
          latitude={@state.latitude}
          longitude={@state.longitude}
          zoom={@state.zoom}
          onBoundsChange={@handleMapChange}
          notes={@state.notes} />
      </div>
      { if @state.viewing?
          <NoteView
            note={@state.viewing}
            onBack={=> window.location.hash = '#'}
          />
        else
          <div>
            <SearchBox
              tags={@props.game.tags}
              checkedTags={@state.checkedTags}
              searchText={@state.searchText}
              onSearch={@handleSearch}
            />
            { if @state.searching
                <p>Searching...</p>
              else
                <Thumbnails notes={@state.notes} />
            }
          </div>
      }
    </div>

  handleSearch: (tags, text, wait = true) ->
    if tags? and text?
      @setState
        checkedTags: tags
        searchText: text
    else
      tags = @state.checkedTags
      text = @state.searchText
    thisSearch = Date.now()
    @setState
      lastSearch: thisSearch
      searching: true
    setTimeout =>
      if thisSearch is @state.lastSearch
        @props.aris.call 'notes.searchNotes',
          game_id: @props.game.game_id
          order_by: 'recent'
          tag_ids:
            tag.tag_id for tag in tags
          search_terms:
            word for word in text.split(/\s+/) when word isnt ''
        , ({data: notes, returnCode}) =>
          if thisSearch is @state.lastSearch
            @setState searching: false
            if returnCode is 0
              notes =
                for o in notes
                  n = new Note o
                  # hide notes that don't have photos
                  continue unless n.photo_url?
                  n
              @setState notes: notes
              @applyHash notes
    , if wait then 250 else 0

NoteMap = React.createClass
  render: ->
    <GoogleMap
      center={[@props.latitude, @props.longitude]}
      zoom={@props.zoom}
      onBoundsChange={@props.onBoundsChange}>
      { do =>
        note_ids = @props.notes.map((note) => note.note_id)
        max_note_id = Math.max(note_ids...)
        min_note_id = Math.min(note_ids...)
        @props.notes.map (note) =>
          age = (note.note_id - min_note_id) / (max_note_id - min_note_id)
          age_percent = "#{age * 100}%"
          color = "rgb(#{age_percent}, #{age_percent}, #{age_percent})"
          <a key={"marker-#{note.note_id}"} lat={note.latitude} lng={note.longitude} href={"##{note.note_id}"}>
            <div style={width: '10px', height: '10px', backgroundColor: color} />
          </a>
      }
    </GoogleMap>

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.latitude isnt nextProps.latitude or
    @props.longitude isnt nextProps.longitude or
    @props.zoom isnt nextProps.zoom or
    @props.notes isnt nextProps.notes or
    @props.onBoundsChange isnt nextProps.onBoundsChange
    # is the onBoundsChange check necessary? doesn't seem to hurt performance

Thumbnails = React.createClass
  render: ->
    <div>
      { @props.notes.map (note) =>
          <a key={"thumb-#{note.note_id}"} href={"##{note.note_id}"}>
            <img src={note.thumb_url} />
          </a>
      }
    </div>

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.notes isnt nextProps.notes

$(document).ready ->

  siftr_url = window.location.search.replace('?', '')
  if siftr_url.length is 0
    siftr_url = window.location.pathname.replace(/\//g, '')
  unless siftr_url.match(/[^0-9]/)
    siftr_id = parseInt siftr_url
    siftr_url = null

  continueWithGame = (game) ->

    aris.getTagsForGame
      game_id: game.game_id
    , ({data: tags, returnCode}) =>
      if returnCode is 0 and tags?
        game.tags = tags

        aris.getUsersForGame
          game_id: game.game_id
        , ({data: owners, returnCode}) =>
          if returnCode is 0 and owners?
            game.owners = owners

            React.render <App game={game} aris={aris} />, document.body

  aris = new Aris
  if siftr_id?
    aris.getGame
      game_id: siftr_id
    , ({data: game, returnCode}) ->
      if returnCode is 0 and game?
        continueWithGame game
  else if siftr_url?
    aris.searchSiftrs
      siftr_url: siftr_url
    , ({data: games, returnCode}) ->
      if returnCode is 0 and games.length is 1
        continueWithGame games[0]
