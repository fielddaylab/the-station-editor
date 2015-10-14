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

TopLevel = React.createClass
  getInitialState: ->
    notes: []
    viewing: null
    searching: false
    checkedTags: []
    searchText: ''
    latitude: @props.game.latitude
    longitude: @props.game.longitude
    zoom: @props.game.zoom
  componentDidMount: ->
    @handleSearch [], '', false

  handleMapChange: ([lat, lng], zoom, bounds, marginBounds) ->
    @setState
      latitude: lat
      longitude: lng
      zoom: zoom

  render: ->
    <div>
      <h1>{ @props.game.name }</h1>
      <h2>A Siftr by { (u.display_name for u in @props.game.owners).join(', ') }</h2>
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} />
      <div style={width: '500px', height: '500px'}>
        <GoogleMap
          center={[@state.latitude, @state.longitude]}
          zoom={@state.zoom}
          onBoundsChange={@handleMapChange}>
          { @state.notes.map (note) =>
              <div key={"marker-#{note.note_id}"} lat={note.latitude} lng={note.longitude}
                style={width: '10px', height: '10px', backgroundColor: 'black', cursor: 'pointer'}
                onClick={=> @setState viewing: note} />
          }
        </GoogleMap>
      </div>
      { if @state.viewing?
          <NoteView
            note={@state.viewing}
            onBack={=> @setState viewing: null}
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
                @state.notes.map (note) =>
                  <a key={"thumb-#{note.note_id}"} href="#" onClick={=> @setState viewing: note}>
                    <img src={note.thumb_url} />
                  </a>
            }
          </div>
      }
    </div>

  handleSearch: (tags, text, wait = true) ->
    @setState
      checkedTags: tags
      searchText: text
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
              @setState notes:
                for o in notes
                  n = new Note o
                  # hide notes that don't have photos
                  continue unless n.photo_url?
                  n
    , if wait then 250 else 0

$(document).ready ->

  aris = new Aris
  aris.getGame
    game_id: 4693
  , ({data: game, returnCode}) ->
    if returnCode is 0 and game?

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

              React.render <TopLevel game={game} aris={aris} />, document.getElementById('output')
