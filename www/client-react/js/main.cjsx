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
  displayName: 'App'

  propTypes:
    game: T.instanceOf Game
    aris: T.instanceOf Aris

  getInitialState: ->
    notes: []
    searchedNotes: []
    fetching: false
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
    searchMinDate: null
    searchMaxDate: null
    notesMinDate: null
    notesMaxDate: null

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
    @refreshNotes()

  applyHash: (notes) ->
    hash = window.location.hash[1..]
    @setState (previousState, currentProps) =>
      update previousState,
        screen:
          $apply: (previousScreen) =>
            if hash is 'new'
              match previousState.login,
                loggedIn: =>
                  match previousScreen,
                    create: => previousScreen
                  , =>
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
                loggedOut: =>
                  main: {}
            else
              note_id = parseInt hash
              matchingNotes =
                note for note in notes ? @state.notes when note.note_id is note_id
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
              notes={@state.searchedNotes ? []} />
          </div>
        match @state.screen,
          main: =>
            <div>
              { noteMap }
              <SearchBox
                tags={@props.game.tags}
                checkedTags={@state.checkedTags}
                searchText={@state.searchText}
                searchMinDate={@state.searchMinDate}
                searchMaxDate={@state.searchMaxDate}
                notesMinDate={@state.notesMinDate}
                notesMaxDate={@state.notesMaxDate}
                onSearch={@handleSearch}
              />
              { if @state.fetching
                  <p>Retrieving notes...</p>
                else if @state.searchedNotes?
                  <Thumbnails notes={@state.searchedNotes} />
                else
                  <p>Searching...</p>
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
              onSubmit={@uploadNewNote}
              />
      }
    </div>

  refreshNotes: ->
    @setState fetching: true
    @props.aris.call 'notes.searchNotes',
      game_id: @props.game.game_id
    , ({data: notes, returnCode}) =>
      notes =
        for o in notes
          n = new Note o
          # hide notes that don't have photos
          continue unless n.photo_url?
          n
      notesMinDate = notesMaxDate = notes[0]?.created
      for note in notes
        d = note.created
        notesMinDate = d if d.getTime() < notesMinDate.getTime()
        notesMaxDate = d if notesMaxDate.getTime() < d.getTime()
      @setState
        notes: notes
        searchedNotes: null
        fetching: false
        notesMinDate: notesMinDate
        notesMaxDate: notesMaxDate
      @applyHash notes
      @handleSearch @state.checkedTags, @state.searchText, @state.minDate, @state.maxDate

  handleSearch: (tags, text, searchMinDate, searchMaxDate) ->
    thisSearch = Date.now()
    @setState
      checkedTags: tags
      searchText: text
      searchMinDate: searchMinDate
      searchMaxDate: searchMaxDate
      lastSearch: thisSearch
    setTimeout =>
      if thisSearch is @state.lastSearch
        words =
          word.toLowerCase() for word in text.split(/\s+/) when word isnt ''
        checkedTagIDs =
          tag.tag_id for tag in tags
        @setState
          searchedNotes:
            for note in @state.notes
              if checkedTagIDs.length > 0
                continue unless note.tag_id in checkedTagIDs
              searchables =
                [ note.description
                , note.user.display_name
                , (comment.description for comment in note.comments)...
                ].map (s) => s.toLowerCase()
              continue unless words.every (word) =>
                searchables.some (thing) =>
                  thing.indexOf(word) >= 0
              if searchMinDate?
                continue unless searchMinDate.getTime() <= note.created.getTime()
              if searchMaxDate?
                continue unless searchMaxDate.getTime() >= note.created.getTime()
              note
    , 250

  uploadNewNote: ->
    match @state.screen,
      create: ({description, tag, url, noteLatitude, noteLongitude}) =>

        typeMap =
          jpg: 'image/jpeg'
          png: 'image/png'
          gif: 'image/gif'
        media_ext = null
        media_base64 = null
        for ext, mime of typeMap
          prefix = "data:#{mime};base64,"
          if url.substring(0, prefix.length) is prefix
            media_ext = ext
            media_base64 = url.substring(prefix.length)
            break
        return unless media_ext? and media_base64?

        @props.aris.call 'notes.createNote',
          game_id: @props.game.game_id
          media:
            file_name: "upload.#{media_ext}"
            data: media_base64
            resize: 640
          description: description
          trigger:
            latitude: noteLatitude
            longitude: noteLongitude
          tag_id: tag.tag_id
        , ({returnCode}) =>
          if returnCode is 0
            @refreshNotes()
            window.location.hash = ""

    , (=>) # do nothing if not in create screen

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
