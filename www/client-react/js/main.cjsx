React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
{markdown} = require 'markdown'
{Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} = require '../../shared/aris.js'
GoogleMap = require 'google-map-react'
{fitBounds} = require 'google-map-react/utils'
$ = require 'jquery'

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
    notes:        []
    map_notes:    []
    map_clusters: []
    page: 1
    latitude:  @props.game.latitude
    longitude: @props.game.longitude
    zoom:      @props.game.zoom
    min_latitude:  null
    max_latitude:  null
    min_longitude: null
    max_longitude: null
    search: ''
    mine: false
    order: 'recent'
    checked_tags: do =>
      o = {}
      for tag in @props.game.tags
        o[tag.tag_id] = false
      o
    modal: nothing: {}
    login_status:
      logged_out:
        username: ''
        password: ''
    view_focus: 'map' # 'map' or 'thumbnails'
    search_controls: null # null, 'not_time', or 'time'
    account_menu: false
    message: null

  updateState: (obj) ->
    @setState (previousState) =>
      update previousState, obj

  componentDidMount: ->
    @login()

  handleMapChange: ({center: {lat, lng}, zoom, bounds: {nw, se}}) ->
    @search 0,
      latitude:      $set: lat
      longitude:     $set: lng
      zoom:          $set: zoom
      min_latitude:  $set: se.lat
      max_latitude:  $set: nw.lat
      min_longitude: $set: nw.lng
      max_longitude: $set: se.lng

  search: (wait = 0, updater = {}, logged_in = @state.login_status.logged_in?) ->
    @setState (previousState) =>
      newState = update update(previousState, updater), page: {$set: 1}
      thisSearch = @lastSearch = Date.now()
      setTimeout =>
        return unless thisSearch is @lastSearch
        @props.aris.call 'notes.siftrSearch',
          game_id: @props.game.game_id
          min_latitude: newState.min_latitude
          max_latitude: newState.max_latitude
          min_longitude: newState.min_longitude
          max_longitude: newState.max_longitude
          zoom: newState.zoom
          limit: 50
          order: newState.order
          filter: if newState.mine and logged_in then 'mine' else undefined
          tag_ids:
            tag_id for tag_id, checked of newState.checked_tags when checked
          search: newState.search
        , @successAt 'performing your search', (data) =>
          return unless thisSearch is @lastSearch
          @setState
            notes:        data.notes
            map_notes:    data.map_notes
            map_clusters: data.map_clusters
      , wait
      newState

  setPage: (page) ->
    thisSearch = @lastSearch = Date.now()
    @props.aris.call 'notes.siftrSearch',
      game_id: @props.game.game_id
      min_latitude: @state.min_latitude
      max_latitude: @state.max_latitude
      min_longitude: @state.min_longitude
      max_longitude: @state.max_longitude
      zoom: @state.zoom
      limit: 50
      offset: (page - 1) * 50
      order: @state.order
      filter: if @state.mine then 'mine' else undefined
      tag_ids:
        tag_id for tag_id, checked of @state.checked_tags when checked
      search: @state.search
      map_data: false
    , @successAt 'loading your search results', (data) =>
      return unless thisSearch is @lastSearch
      @setState
        notes: data.notes
        page:  page

  fetchComments: (note) ->
    @props.aris.getNoteCommentsForNote
      game_id: @props.game.game_id
      note_id: note.note_id
    , @successAt 'fetching comments', (data) =>
      @updateState
        modal:
          viewing_note:
            $apply: (view) =>
              if view.note is note
                update view, comments: {$set: data}
              else
                view

  login: ->
    match @state.login_status,
      logged_out: ({username, password}) =>
        @props.aris.login (username or undefined), (password or undefined), =>
          @search undefined, undefined, true if @props.aris.auth?
          failed_login = @state.account_menu and not @props.aris.auth?
          @setState
            login_status:
              if @props.aris.auth?
                logged_in:
                  auth: @props.aris.auth
              else
                logged_out:
                  username: username
                  password: ''
            account_menu: failed_login
            message: if failed_login then 'Incorrect username or password.' else null

  logout: ->
    @props.aris.logout()
    @setState
      login_status:
        logged_out:
          username: ''
          password: ''
      mine: false
      modal: nothing: {}
      account_menu: false
      message: null
    @search undefined, undefined, false

  successAt: (doingSomething, fn) -> (arisResult) =>
    {data, returnCode} = arisResult
    if data? and returnCode is 0
      fn data
    else
      @setState message:
        "There was a problem #{doingSomething}. Please report this error: #{JSON.stringify arisResult}"

  render: ->
    leftPanel = {position: 'fixed', top: 77, left: 0, width: '70%', height: 'calc(100% - 77px)'}
    topRightPanel = {position: 'fixed', top: 77, left: '70%', width: '30%', height: 400}
    bottomRightPanel = {position: 'fixed', top: 477, left: '70%', width: '30%', height: 'calc(100% - 477px)'}
    rightPanel = {position: 'fixed', top: 77, left: '70%', width: '30%', height: 'calc(100% - 77px)'}
    mapPanel = if @state.view_focus is 'map'
      leftPanel
    else if @state.search_controls is null
      rightPanel
    else
      bottomRightPanel
    searchPanel = if @state.search_controls is null
      display: 'none'
    else
      topRightPanel
    thumbnailsPanel = if @state.view_focus is 'thumbnails'
      leftPanel
    else if @state.search_controls is null
      rightPanel
    else
      bottomRightPanel
    tag_ids = @props.game.tags.map (tag) => tag.tag_id
    <div style={fontFamily: 'sans-serif'}>
      <div ref="theMapDiv" style={mapPanel}>
        <GoogleMap
          center={[@state.latitude, @state.longitude]}
          zoom={Math.max 2, @state.zoom}
          options={minZoom: 2}
          draggable={not (@state.modal.move_point?.dragging ? false)}
          onChildMouseDown={(hoverKey, childProps, mouse) =>
            if hoverKey is 'draggable-point'
              # window.p = @refs.draggable_point
              # console.log [p, mouse.x, mouse.y]
              @updateState modal: move_point: dragging: $set: true
          }
          onChildMouseUp={(hoverKey, childProps, mouse) =>
            @setState (previousState) =>
              if previousState.modal.move_point?
                update previousState, modal: move_point: dragging: $set: false
              else
                previousState
          }
          onChildMouseMove={(hoverKey, childProps, mouse) =>
            if hoverKey is 'draggable-point'
              @updateState
                modal:
                  move_point:
                    latitude: {$set: mouse.lat}
                    longitude: {$set: mouse.lng}
          }
          onChange={@handleMapChange}>
          { if @state.modal.move_point?
              <div
                key="draggable-point"
                ref="draggable_point"
                lat={@state.modal.move_point.latitude}
                lng={@state.modal.move_point.longitude}
                style={marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: '#e26', border: '2px solid black', cursor: 'pointer'}
              />
            else
              []
          }
          { if @state.modal.move_point?
              []
            else
              @state.map_notes.map (note) =>
                color = @props.game.colors["tag_#{tag_ids.indexOf(parseInt note.tag_id) + 1}"] ? 'white'
                <div key={note.note_id}
                  lat={note.latitude}
                  lng={note.longitude}
                  onClick={=>
                    @setState
                      modal:
                        viewing_note:
                          note: note
                          comments: null
                          new_comment: ''
                    @fetchComments note
                  }
                  style={marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: color, border: '2px solid black', cursor: 'pointer'}
                  />
          }
          { if @state.modal.move_point?
              []
            else
              for cluster, i in @state.map_clusters
                lat = cluster.min_latitude + (cluster.max_latitude - cluster.min_latitude) / 2
                lng = cluster.min_longitude + (cluster.max_longitude - cluster.min_longitude) / 2
                if -180 < lng < 180 && -90 < lat < 90
                  do (cluster) =>
                    colors =
                      for tag_id of cluster.tags
                        @props.game.colors["tag_#{tag_ids.indexOf(parseInt tag_id) + 1}"]
                    gradient =
                      if colors.length is 1
                        colors[0]
                      else
                        "linear-gradient(to bottom right, #{colors.join(', ')})"
                    <div key={"#{lat}-#{lng}"}
                      lat={lat}
                      lng={lng}
                      onClick={=>
                        if cluster.min_latitude is cluster.max_latitude and cluster.min_longitude is cluster.min_longitude
                          # Calling fitBounds on a single point breaks for some reason
                          @setState
                            latitude: cluster.min_latitude
                            longitude: cluster.min_longitude
                            zoom: 21
                        else
                          bounds =
                            nw:
                              lat: cluster.max_latitude
                              lng: cluster.min_longitude
                            se:
                              lat: cluster.min_latitude
                              lng: cluster.max_longitude
                          size =
                            width: @refs.theMapDiv.clientWidth
                            height: @refs.theMapDiv.clientHeight
                          {center, zoom} = fitBounds bounds, size
                          @setState
                            latitude: center.lat
                            longitude: center.lng
                            zoom: zoom
                      }
                      style={marginLeft: '-10px', marginTop: '-10px', width: '20px', height: '20px', border: '2px solid black', background: gradient, color: 'black', cursor: 'pointer', textAlign: 'center', display: 'table', fontWeight: 'bold'}>
                      <span style={display: 'table-cell', verticalAlign: 'middle'}>{ cluster.note_count }</span>
                    </div>
                else
                  continue
          }
        </GoogleMap>
      </div>
      <div style={update searchPanel, overflowY: {$set: 'scroll'}}>
        <p>
          <input type="text" value={@state.search} placeholder="Search..."
            onChange={(e) => @search 200, search: {$set: e.target.value}}
          />
        </p>
        <p>
          <label>
            <input type="radio" checked={@state.order is 'recent'}
              onChange={(e) =>
                if e.target.checked
                  @search 0, order: {$set: 'recent'}
              }
            />
            Recent
          </label>
        </p>
        <p>
          <label>
            <input type="radio" checked={@state.order is 'popular'}
              onChange={(e) =>
                if e.target.checked
                  @search 0, order: {$set: 'popular'}
              }
            />
            Popular
          </label>
        </p>
        { if @state.login_status.logged_in?
            <p>
              <label>
                <input type="checkbox" checked={@state.mine}
                  onChange={(e) =>
                    @search 0, mine: {$set: e.target.checked}
                  }
                />
                My Notes
              </label>
            </p>
        }
        <p>
          <b>Tags</b>
        </p>
        { @props.game.tags.map (tag) =>
            <p key={tag.tag_id}>
              <label>
                <input type="checkbox" checked={@state.checked_tags[tag.tag_id]}
                  onClick={=> @search 0,
                    checked_tags: do =>
                      o = {}
                      o[tag.tag_id] =
                        $apply: (x) => not x
                      o
                  }
                />
                { tag.tag }
              </label>
            </p>
        }
      </div>
      <div style={update thumbnailsPanel, overflowY: {$set: 'scroll'}}>
        { if @state.page isnt 1
            <p>
              <button type="button" onClick={=> @setPage(@state.page - 1)}>Previous Page</button>
            </p>
        }
        { @state.notes.map (note) =>
            <img key={note.note_id} src={note.media.thumb_url} style={width: 120, padding: 5, cursor: 'pointer'}
              onClick={=>
                @setState
                  modal:
                    viewing_note:
                      note: note
                      comments: null
                      new_comment: ''
                @fetchComments note
              } />
        }
        { if @state.notes.length is 50
            <p>
              <button type="button" onClick={=> @setPage(@state.page + 1)}>Next Page</button>
            </p>
        }
      </div>
      <div style={position: 'fixed', top: 0, left: 0, height: 77, width: '100%', backgroundColor: 'rgb(44,48,59)'}>
        <div style={float: 'left'}>
          <a href="..">
            <img src="img/brand.png" />
          </a>
        </div>
        <div style={float: 'left', cursor: 'pointer'}>
          <img src={if @state.view_focus is 'map' then 'img/map-on.png' else 'img/map-off.png'}
            onClick={=>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @setState view_focus: 'map'
            }
          />
        </div>
        <div style={float: 'left', cursor: 'pointer'}>
          <img src={if @state.view_focus is 'thumbnails' then 'img/thumbs-on.png' else 'img/thumbs-off.png'}
            onClick={=>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @setState view_focus: 'thumbnails'
            }
          />
        </div>
        <div style={float: 'right', cursor: 'pointer'}>
          <img src={if @state.search_controls? then 'img/search-on.png' else 'img/search-off.png'}
            onClick={=>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @setState search_controls: if @state.search_controls? then null else 'not_time'
            }
          />
        </div>
        <div style={float: 'right'}>
          <a href="..">
            <img src="img/discover.png" />
          </a>
        </div>
        <div style={float: 'right', cursor: 'pointer'}>
          <img src="img/my-account.png"
            onClick={=>
              @setState account_menu: not @state.account_menu
            }
          />
        </div>
        <div style={float: 'right'}>
          <a href="../editor">
            <img src="img/my-siftrs.png" />
          </a>
        </div>
      </div>
      <div style={
        display: if @state.login_status.logged_in? then 'block' else 'none'
        position: 'fixed'
        cursor: 'pointer'
        top: 95
        left: 'calc(70% - 203px)'
      }>
        <img src="img/add-item.png"
          onClick={=> @setState modal: select_photo: {}}
          style={boxShadow: '2px 2px 2px 1px rgba(0, 0, 0, 0.2)'}
        />
      </div>
      <div style={
        display: if @state.account_menu then 'block' else 'none'
        position: 'fixed'
        top: 77
        left: 'calc(100% - 350px)'
        backgroundColor: 'rgb(44,48,59)'
        color: 'white'
        paddingLeft: 10
        paddingRight: 10
        width: 175
      }>
        { match @state.login_status,
            logged_out: ({username, password}) =>
              <div>
                <p style={width: '100%'}>
                  <input autoCapitalize="off" autoCorrect="off" type="text" value={username} placeholder="Username"
                    onChange={(e) =>
                      @setState
                        login_status:
                          logged_out:
                            username: e.target.value
                            password: password
                    }
                    style={width: '100%', boxSizing: 'border-box'}
                    onKeyDown={(e) => @login() if e.keyCode is 13}
                    />
                </p>
                <p style={width: '100%'}>
                  <input autoCapitalize="off" autoCorrect="off" type="password" value={password} placeholder="Password"
                    onChange={(e) =>
                      @setState
                        login_status:
                          logged_out:
                            username: username
                            password: e.target.value
                    }
                    style={width: '100%', boxSizing: 'border-box'}
                    onKeyDown={(e) => @login() if e.keyCode is 13}
                    />
                </p>
                <p>
                  <button type="button" onClick={@login}>Login</button>
                </p>
              </div>
            logged_in: ({auth}) =>
              <div>
                <p>
                  Logged in as {auth.username}
                </p>
                <p>
                  <button type="button" onClick={@logout}>Logout</button>
                </p>
              </div>
        }
      </div>
      { match @state.modal,
          nothing: => ''
          viewing_note: ({note, comments, new_comment}) =>
            <div style={position: 'fixed', top: '10%', height: '80%', left: 'calc((100% - 300px) * 0.1)', width: 'calc((100% - 300px) * 0.8)', overflowY: 'scroll', backgroundColor: 'white', border: '1px solid black'}>
              <div style={padding: '20px'}>
                <p><button type="button" onClick={=> @setState modal: {nothing: {}}}>Close</button></p>
                <img src={note.media.url} style={width: '100%'} />
                <p>{ note.description }</p>
                { if comments?
                    for comment in comments
                      <div key={comment.comment_id}>
                        <h4>{ comment.user.display_name } at { comment.created.toLocaleString() }</h4>
                        <p>{ comment.description }</p>
                      </div>
                  else
                    <p>Loading comments...</p>
                }
                { if @state.login_status.logged_in?
                    <div>
                      <textarea placeholder="Post a new comment..." value={new_comment}
                        onChange={(e) =>
                          @updateState modal: viewing_note: new_comment: $set: e.target.value
                        }
                      />
                      <p>
                        <button type="button" onClick={=>
                          @props.aris.createNoteComment
                            game_id: @props.game.game_id
                            note_id: note.note_id
                            description: new_comment
                          , @successAt 'posting your comment', (comment) =>
                            @fetchComments note
                            @updateState modal: viewing_note: new_comment: $set: ''
                        }>Submit</button>
                      </p>
                    </div>
                  else
                    <p>
                      <b onClick={=> @setState account_menu: true} style={cursor: 'pointer'}>Login</b>
                      to post a new comment
                    </p>
                }
              </div>
            </div>
          select_photo: =>
            <div style={position: 'fixed', top: '10%', height: '80%', left: 'calc((100% - 300px) * 0.1)', width: 'calc((100% - 300px) * 0.8)', overflowY: 'scroll', backgroundColor: 'white', border: '1px solid black'}>
              <div style={padding: '20px'}>
                <p><button type="button" onClick={=> @setState modal: {nothing: {}}}>Close</button></p>
                <form ref="file_form">
                  <p><input type="file" accept="image/*" capture="camera" name="raw_upload" ref="file_input" /></p>
                  <p>
                    <button type="button" onClick={=>
                      if @refs.file_input.files[0]?
                        name = @refs.file_input.files[0].name
                        ext = name[name.indexOf('.') + 1 ..]
                        @setState modal: uploading_photo: {}
                        $.ajax
                          url: "#{ARIS_URL}/rawupload.php"
                          type: 'POST'
                          success: (raw_upload_id) =>
                            @props.aris.call 'media.createMediaFromRawUpload',
                              file_name: "upload.#{ext}"
                              raw_upload_id: raw_upload_id
                              game_id: @props.game.game_id
                              resize: 800
                            , @successAt 'uploading your photo', (media) =>
                              if @state.modal.uploading_photo?
                                @setState
                                  modal:
                                    photo_details:
                                      media: media
                                      tag: @props.game.tags[0]
                                      description: ''
                                  message: null
                          data: new FormData @refs.file_form
                          cache: false
                          contentType: false
                          processData: false
                      }>
                      Begin Upload
                    </button>
                  </p>
                </form>
              </div>
            </div>
          uploading_photo: =>
            <div style={position: 'fixed', top: '10%', height: '80%', left: 'calc((100% - 300px) * 0.1)', width: 'calc((100% - 300px) * 0.8)', overflowY: 'scroll', backgroundColor: 'white', border: '1px solid black'}>
              <div style={padding: '20px'}>
                <p><button type="button" onClick={=> @setState modal: {nothing: {}}}>Close</button></p>
                <p>Uploading, please wait...</p>
              </div>
            </div>
          photo_details: ({media, tag, description}) =>
            <div style={position: 'fixed', top: '10%', height: '80%', left: 'calc((100% - 300px) * 0.1)', width: 'calc((100% - 300px) * 0.8)', overflowY: 'scroll', backgroundColor: 'white', border: '1px solid black'}>
              <div style={padding: '20px'}>
                <p><button type="button" onClick={=> @setState modal: {nothing: {}}}>Close</button></p>
                <p><img src={media.thumb_url} /></p>
                { @props.game.tags.map (some_tag) =>
                    <p key={some_tag.tag_id}>
                      <label>
                        <input type="radio" checked={some_tag is tag}
                          onChange={(e) =>
                            if e.target.checked
                              @updateState modal: photo_details: tag: $set: some_tag
                          }
                        />
                        { some_tag.tag }
                      </label>
                    </p>
                }
                <p>
                  <textarea style={width: '100%', height: '100px'} value={description} onChange={(e) =>
                    @updateState modal: photo_details: description: $set: e.target.value
                  }/>
                </p>
                <p>
                  <button type="button" onClick={=>
                    if description is ''
                      @setState message: 'Please type a caption for your photo.'
                    else
                      @updateState
                        modal:
                          $apply: ({photo_details}) =>
                            move_point:
                              update photo_details,
                                latitude: $set: @props.game.latitude
                                longitude: $set: @props.game.longitude
                                dragging: $set: false
                  }>Next Step</button>
                </p>
              </div>
            </div>
          move_point: ({media, tag, description, latitude, longitude}) =>
            <div style={position: 'fixed', left: 200, top: 5, padding: 5, backgroundColor: 'gray', color: 'white', border: '1px solid black'}>
              <p>
                <button type="button" onClick={=>
                  @props.aris.call 'notes.createNote',
                    game_id: @props.game.game_id
                    description: description
                    media_id: media.media_id
                    trigger: {latitude, longitude}
                    tag_id: tag.tag_id
                  , @successAt 'creating your note', (note) =>
                    @setState modal: nothing: {} # TODO: fetch and view note
                    @search()
                }>Create Note</button>
              </p>
              <p>
                <button type="button" onClick={=> @setState modal: {nothing: {}}}>
                  Cancel
                </button>
              </p>
            </div>
      }
      { if @state.message?
          <div style={position: 'fixed', left: 100, width: 'calc(100% - 300px)', top: 'calc(50% - 50px)', backgroundColor: 'black', color: 'white', textAlign: 'center', padding: 50}>
            { @state.message }
            <div style={position: 'absolute', left: 10, top: 10, cursor: 'pointer'} onClick={=> @setState message: null}>
              X
            </div>
          </div>
      }
    </div>

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

        aris.getColors
          colors_id: game.colors_id ? 1
        , ({data: colors, returnCode}) =>
          if returnCode is 0 and colors?
            game.colors = colors

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
