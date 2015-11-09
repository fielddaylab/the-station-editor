React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
{markdown} = require 'markdown'
{Game, Colors, User, Tag, Comment, Note, Aris} = require '../../shared/aris.js'
{NoteView} = require './components/NoteView.js'
{NoteMap} = require './components/NoteMap.js'
{Uploader} = require './components/Uploader.js'
{SearchBox} = require './components/SearchBox.js'
{Thumbnails} = require './components/Thumbnails.js'

T = React.PropTypes

renderMarkdown = (str) ->
  __html: markdown.toHTML str

# This is Haskell right? It uses indentation and everything
match = (val, branches, def = (-> throw 'Match failed')) ->
  for k, v of branches
    if k of val
      return v val[k]
  def()

App = React.createClass
  propTypes:
    game: T.instanceOf Game
    aris: T.instanceOf Aris

  getInitialState: ->
    notes: []
    searching: false
    checkedTags: []
    searchText: ''
    latitude: @props.game.latitude
    longitude: @props.game.longitude
    zoom: @props.game.zoom
    login:
      loggedOut:
        username: ''
        password: ''
    screen:
      main: {}

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
    @setState (previousState, currentProps) =>
      update previousState,
        login:
          $set:
            if @props.aris.auth?
              loggedIn:
                auth: @props.aris.auth
            else
              match previousState.login,
                loggedIn:               => loggedOut: {username: '', password: ''}
                loggedOut: ({username}) => loggedOut: {username    , password: ''}
    @handleSearch undefined, undefined, false

  applyHash: (notes) ->
    hash = window.location.hash[1..]
    @setState (previousState, currentProps) =>
      if hash is 'new'
        if 'create' of previousState.screen
          previousState
        else
          update previousState,
            screen:
              $set:
                create:
                  description: ''
                  url: null
                  tags: @props.game.tags
                  tag: @props.game.tags[0]
                  latitude: @props.game.latitude
                  longitude: @props.game.longitude
                  zoom: @props.game.zoom
                  noteLatitude: @props.game.latitude
                  noteLongitude: @props.game.longitude
      else
        note_id = parseInt hash
        matchingNotes =
          note for note in notes ? @state.notes when note.note_id is note_id
        update previousState,
          screen:
            $set:
              if matchingNotes.length is 1
                view:
                  note: matchingNotes[0]
              else
                main: {}

  handleMapChange: ({center: {lat, lng}, zoom}) ->
    @setState
      latitude: lat
      longitude: lng
      zoom: zoom

  setUsername: (username) ->
    @setState (previousState, currentProps) ->
      update previousState,
        login:
          $apply: (login) =>
            match login,
              loggedIn:               => login
              loggedOut: ({password}) => loggedOut: {username, password}

  setPassword: (password) ->
    @setState (previousState, currentProps) ->
      update previousState,
        login:
          $apply: (login) =>
            match login,
              loggedIn:               => login
              loggedOut: ({username}) => loggedOut: {username, password}

  render: ->
    <div>
      { match @state.login,
          loggedIn: ({auth}) =>
            <div>
              <p><code>{ JSON.stringify auth }</code></p>
              <p><button type="button" onClick={@logout}>Logout</button></p>
              <p><button type="button" onClick={=> window.location.hash = 'new'}>Add Note</button></p>
            </div>
          loggedOut: ({username, password}) =>
            <form>
              <p>
                <input type="text" placeholder="Username" value={username} onChange={(e) => @setUsername e.target.value} />
              </p>
              <p>
                <input type="password" placeholder="Password" value={password} onChange={(e) => @setPassword e.target.value} />
              </p>
              <p>
                <button type="submit" onClick={(e) => e.preventDefault(); @login(username, password)}>Login</button>
              </p>
            </form>
      }
      <h1>{ @props.game.name }</h1>
      <h2>A Siftr by { (u.display_name for u in @props.game.owners).join(', ') }</h2>
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} />
      { do =>
        noteMap =
          <div style={width: '500px', height: '500px'}>
            <NoteMap
              latitude={@state.latitude}
              longitude={@state.longitude}
              zoom={@state.zoom}
              onBoundsChange={@handleMapChange}
              notes={@state.notes} />
          </div>
        match @state.screen,
          main: =>
            <div>
              { noteMap }
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
          view: ({note}) =>
            <div>
              { noteMap }
              <NoteView
                note={note}
                onBack={=> window.location.hash = '#'}
              />
            </div>
          create: ({description, tag, url, latitude, longitude, zoom, noteLatitude, noteLongitude}) =>
            <Uploader
              description={description}
              tags={@props.game.tags}
              tag={tag}
              url={url}
              onChange={(o) =>
                @setState (previousState, currentProps) =>
                  update previousState,
                    screen:
                      $set:
                        create:
                          description: o.description ? description
                          url: o.url ? url
                          tag: o.tag ? tag
                          latitude: o.latitude ? latitude
                          longitude: o.longitude ? longitude
                          zoom: o.zoom ? zoom
                          noteLatitude: o.noteLatitude ? noteLatitude
                          noteLongitude: o.noteLongitude ? noteLongitude
              }
              latitude={latitude}
              longitude={longitude}
              zoom={zoom}
              noteLatitude={noteLatitude}
              noteLongitude={noteLongitude}
              />
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

document.addEventListener 'DOMContentLoaded', ->

  siftr_url = window.location.search.replace('?', '')
  if siftr_url.length is 0
    siftr_url = window.location.pathname.replace(/\//g, '')
  unless siftr_url.match(/[^0-9]/)
    siftr_id = parseInt siftr_url
    siftr_url = null

  aris = new Aris
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

            ReactDOM.render <App game={game} aris={aris} />, document.getElementById('the-container')

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
