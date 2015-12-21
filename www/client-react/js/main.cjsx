React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
# {markdown} = require 'markdown'
{Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} = require '../../shared/aris.js'
GoogleMap = require 'google-map-react'
{fitBounds} = require 'google-map-react/utils'
$ = require 'jquery'
{make, child, raw, props} = require '../../shared/react-writer.js'

T = React.PropTypes

# renderMarkdown = (str) ->
#   __html: markdown.toHTML str

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

  refreshEditedNote: ->
    @search()
    if @state.modal.viewing_note?
      @props.aris.call 'notes.siftrSearch',
        game_id: @props.game.game_id
        note_id: @state.modal.viewing_note.note.note_id
        map_data: false
      , @successAt 'refreshing this note', (data) =>
        @updateState modal: viewing_note: note: $set: data.notes[0]

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
    if returnCode is 0
      fn data
    else
      @setState message:
        "There was a problem #{doingSomething}. Please report this error: #{JSON.stringify arisResult}"

  render: ->
    tag_ids = @props.game.tags.map (tag) => tag.tag_id

    make 'div#the-contained', =>
      props
        className: """
          #{if @state.search_controls? then 'searching' else ''}
          #{if @state.account_menu then 'accountMenuOpen' else ''}
          """
        style:
          width: '100%'
          height: '100%'
          overflow: 'visible'

      # Map
      child 'div', =>
        props
          ref: 'theMapDiv'
          className: if @state.view_focus is 'map' then 'primaryPane' else 'secondaryPane'

        child GoogleMap, =>
          props
            center: [@state.latitude, @state.longitude]
            zoom: Math.max 2, @state.zoom
            options: minZoom: 2
            draggable: not (@state.modal.move_point?.dragging ? false)
            onChildMouseDown: (hoverKey, childProps, mouse) =>
              if hoverKey is 'draggable-point'
                # window.p = @refs.draggable_point
                # console.log [p, mouse.x, mouse.y]
                @updateState modal: move_point:
                  dragging: $set: true
                  can_reposition: $set: false
            onChildMouseUp: (hoverKey, childProps, mouse) =>
              @setState (previousState) =>
                if previousState.modal.move_point?
                  update previousState, modal: move_point: dragging: $set: false
                else
                  previousState
            onChildMouseMove: (hoverKey, childProps, mouse) =>
              if hoverKey is 'draggable-point'
                @updateState
                  modal:
                    move_point:
                      latitude: {$set: mouse.lat}
                      longitude: {$set: mouse.lng}
            onChange: @handleMapChange

          if @state.modal.move_point?
            child 'div', =>
              props
                key: 'draggable-point'
                ref: 'draggable_point'
                lat: @state.modal.move_point.latitude
                lng: @state.modal.move_point.longitude
                style: {marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: 'white', border: '2px solid black', cursor: 'pointer'}
          else if @state.modal.select_category?
            tag = @state.modal.select_category.tag
            color = @props.game.colors["tag_#{tag_ids.indexOf(tag.tag_id) + 1}"] ? 'black'
            child 'div', =>
              props
                lat: @state.modal.select_category.latitude
                lng: @state.modal.select_category.longitude
                style: {marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: color, border: '2px solid black', cursor: 'pointer'}
          else
            @state.map_notes.forEach (note) =>
              color = @props.game.colors["tag_#{tag_ids.indexOf(parseInt note.tag_id) + 1}"] ? 'white'
              child 'div', =>
                props
                  key: note.note_id
                  lat: note.latitude
                  lng: note.longitude
                  onClick: =>
                    @setState
                      modal:
                        viewing_note:
                          note: note
                          comments: null
                          new_comment: ''
                          confirm_delete: false
                          confirm_delete_comment_id: null
                    @fetchComments note
                  style: {marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: color, border: '2px solid black', cursor: 'pointer'}
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
                  child 'div', =>
                    props
                      key: "#{lat}-#{lng}"
                      lat: lat
                      lng: lng
                      onClick: =>
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
                      style: {marginLeft: '-10px', marginTop: '-10px', width: '20px', height: '20px', border: '2px solid black', background: gradient, color: 'black', cursor: 'pointer', textAlign: 'center', display: 'table', fontWeight: 'bold'}
                    child 'span', =>
                      props style: {display: 'table-cell', verticalAlign: 'middle'}
                      raw cluster.note_count

      # Search
      child 'div.searchPane', =>
        child 'p', =>
          child 'input', =>
            props
              type: 'text'
              value: @state.search
              placeholder: 'Search...'
              onChange: (e) => @search 200, search: {$set: e.target.value}
              style:
                width: '100%'
                boxSizing: 'border-box'

        child 'p', =>
          child 'label', =>
            child 'input', =>
              props
                type: 'radio'
                checked: @state.order is 'recent'
                onChange: (e) => @search 0, order: {$set: 'recent'} if e.target.checked
            raw 'Recent'

        child 'p', =>
          child 'label', =>
            child 'input', =>
              props
                type: 'radio'
                checked: @state.order is 'popular'
                onChange: (e) => @search 0, order: {$set: 'popular'} if e.target.checked
            raw 'Popular'

        if @state.login_status.logged_in?
          child 'p', =>
            child 'label', =>
              child 'input', =>
                props
                  type: 'checkbox'
                  checked: @state.mine
                  onChange: (e) => @search 0, mine: {$set: e.target.checked}
              raw 'My Notes'

        child 'p', => child 'b', => raw 'By Category:'

        child 'p', =>
          @props.game.tags.forEach (tag) =>
            checked = @state.checked_tags[tag.tag_id]
            color = @props.game.colors["tag_#{tag_ids.indexOf(tag.tag_id) + 1}"] ? 'black'
            child 'span', =>
              props
                key: tag.tag_id
                style:
                  margin: 5
                  padding: 5
                  border: "1px solid #{color}"
                  color: if checked then 'white' else color
                  backgroundColor: if checked then color else 'white'
                  borderRadius: 5
                  cursor: 'pointer'
                  whiteSpace: 'nowrap'
                  display: 'inline-block'
                onClick: =>
                  @search 0,
                    checked_tags: do =>
                      o = {}
                      o[tag.tag_id] =
                        $apply: (x) => not x
                      o
              raw "#{if checked then '✓' else '●'} #{tag.tag}"

      # Thumbnails
      child 'div', =>
        props
          className: if @state.view_focus is 'thumbnails' then 'primaryPane' else 'secondaryPane'
          style: {overflowY: 'scroll', textAlign: 'center', backgroundColor: 'white'}

        if @state.page isnt 1
          child 'p', => child 'button', =>
            props
              type: 'button'
              onClick: => @setPage(@state.page - 1)
            raw 'Previous Page'

        @state.notes.forEach (note) =>
          child 'img',
            key: note.note_id
            src: note.media.thumb_url
            style: {width: 120, padding: 5, cursor: 'pointer'}
            onClick: =>
              @setState
                modal:
                  viewing_note:
                    note: note
                    comments: null
                    new_comment: ''
                    confirm_delete: false
                    confirm_delete_comment_id: null
              @fetchComments note

        if @state.notes.length is 50
          child 'p', => child 'button', =>
            props
              type: 'button'
              onClick: => @setPage(@state.page + 1)
            raw 'Next Page'

      # Desktop menu, also mobile bottom bar
      child 'div.desktopMenu', =>

        child 'div.menuBrand', =>
          child 'a', href: '..', =>
            child 'img', src: 'img/brand.png'

        child 'div.menuMap', style: {cursor: 'pointer'}, =>
          child 'img',
            src: if @state.view_focus is 'map' then 'img/map-on.png' else 'img/map-off.png'
            onClick: =>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @updateState
                view_focus: $set: 'map'
                modal: $apply: (modal) =>
                  if modal.viewing_note?
                    nothing: {}
                  else
                    modal

        child 'div.menuThumbs', style: {cursor: 'pointer'}, =>
          child 'img',
            src: if @state.view_focus is 'thumbnails' then 'img/thumbs-on.png' else 'img/thumbs-off.png'
            onClick: =>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @updateState
                view_focus: $set: 'thumbnails'
                modal: $apply: (modal) =>
                  if modal.viewing_note?
                    nothing: {}
                  else
                    modal

        child 'div.menuSift', style: {cursor: 'pointer'}, =>
          child 'img',
            src: if @state.search_controls? then 'img/search-on.png' else 'img/search-off.png'
            onClick: =>
              setTimeout =>
                window.dispatchEvent new Event 'resize'
              , 500
              @setState search_controls: if @state.search_controls? then null else 'not_time'

        child 'div.menuDiscover', =>
          child 'a', href: '..', =>
            child 'img', src: 'img/discover.png'

        child 'div.menuMyAccount', style: {cursor: 'pointer'}, =>
          child 'img',
            src: "img/my-account.png"
            onClick: => @setState account_menu: not @state.account_menu

        child 'div.menuMySiftrs', =>
          child 'a', href: '../editor', =>
            child 'img', src: 'img/my-siftrs.png'

      # Desktop and mobile add buttons
      clickAdd = =>
        if @state.login_status.logged_in?
          @setState modal: select_photo: {}
        else
          @setState account_menu: true
      if @state.search_controls is null and (@state.modal.nothing? or @state.modal.viewing_note?)
        child 'div.addItemDesktop', =>
          props
            style:
              position: 'absolute'
              cursor: 'pointer'
              top: 95
              left:
                if @state.view_focus is 'map'
                  'calc(70% - 203px)'
                else
                  'calc(70% + 17px)'
          child 'img',
            src: 'img/add-item.png'
            onClick: clickAdd
            style: {boxShadow: '2px 2px 2px 1px rgba(0, 0, 0, 0.2)'}
      child 'img.addItemMobile',
        src: 'img/mobile-plus.png'
        style:
          position: 'absolute'
          bottom: 0
          left: 'calc(50% - (77px * 0.5))'
          cursor: 'pointer'
        onClick: clickAdd

      # Desktop account menu
      usernameBox = (username, style = {}) =>
        child 'input', =>
          props
            autoCapitalize: 'off'
            autoCorrect: 'off'
            type: 'text'
            value: username
            placeholder: 'Username'
            onChange: (e) => @updateState login_status: logged_out: username: $set: e.target.value
            style: style
            onKeyDown: (e) => @login() if e.keyCode is 13
      passwordBox = (password, style = {}) =>
        child 'input', =>
          props
            autoCapitalize: 'off'
            autoCorrect: 'off'
            type: 'password'
            value: password
            placeholder: 'Password'
            onChange: (e) => @updateState login_status: logged_out: password: $set: e.target.value
            style: style
            onKeyDown: (e) => @login() if e.keyCode is 13
      child 'div.accountMenuDesktop', =>
        props
          style:
            position: 'absolute'
            top: 77
            left: 'calc(100% - 350px)'
            backgroundColor: 'rgb(44,48,59)'
            color: 'white'
            paddingLeft: 10
            paddingRight: 10
            width: 175
        child 'div', =>
          child 'img',
            src: 'img/x-white.png'
            style: cursor: 'pointer'
            onClick: => @setState account_menu: false
        match @state.login_status,
          logged_out: ({username, password}) =>
            child 'div', =>
              child 'p', =>
                props style: {width: '100%'}
                usernameBox username, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                props style: {width: '100%'}
                passwordBox password, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                child 'button', =>
                  props type: 'button', onClick: @login
                  raw 'Login'
          logged_in: ({auth}) =>
            child 'div', =>
              child 'p', => raw "Logged in as #{auth.username}"
              child 'p', =>
                child 'button', =>
                  props type: 'button', onClick: @logout
                  raw 'Logout'

      # Mobile account menu
      child 'div.accountMenuMobile', =>
        props
          style:
            backgroundColor: 'rgb(44,48,59)'
            color: 'white'
            paddingLeft: 10
            paddingRight: 10
            paddingTop: 10
            boxSizing: 'border-box'
        child 'div', =>
          child 'img',
            src: 'img/x-white.png'
            style: cursor: 'pointer'
            onClick: => @setState account_menu: false
        match @state.login_status,
          logged_out: ({username, password}) =>
            child 'div', =>
              child 'p', =>
                props style: {width: '100%'}
                usernameBox username, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                props style: {width: '100%'}
                passwordBox password, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                child 'button', =>
                  props type: 'button', onClick: @login
                  raw 'Login'
          logged_in: ({auth}) =>
            child 'div', =>
              child 'p', => raw "Logged in as #{auth.username}"
              child 'p', =>
                child 'button', =>
                  props type: 'button', onClick: @logout
                  raw 'Logout'

      # Main modal
      match @state.modal,
        nothing: => null
        viewing_note: ({note, comments, new_comment, confirm_delete, confirm_delete_comment_id, edit_comment_id, edit_comment_text}) =>
          child 'div.primaryModal', =>
            props
              style:
                overflowY: 'scroll'
                backgroundColor: 'white'
            child 'img',
              src: 'img/x-blue.png'
              style:
                position: 'absolute'
                top: 20
                right: 20
                cursor: 'pointer'
              onClick: => @setState modal: nothing: {}
            child 'div.noteView', =>
              child 'div', =>
                props
                  style:
                    backgroundImage: "url(#{note.media.url})"
                    backgroundSize: 'contain'
                    backgroundRepeat: 'no-repeat'
                    backgroundPosition: 'center'
                    width: '100%'
                    height: 'calc(100vh - 200px)'
              child 'h4', =>
                raw "#{note.display_name} at #{new Date(note.created.replace(' ', 'T') + 'Z').toLocaleString()}"
              child 'p', => raw note.description
              if @state.login_status.logged_in?
                user_id = @state.login_status.logged_in.auth.user_id
                owners =
                  owner.user_id for owner in @props.game.owners
                if note.published is 'PENDING'
                  if user_id in owners
                    child 'p', =>
                      raw 'This note needs your approval to be visible.'
                      raw ' '
                      child 'button', =>
                        props
                          type: 'button'
                          onClick: =>
                            @props.aris.call 'notes.approveNote',
                              note_id: note.note_id
                            , @successAt 'approving this note', => @refreshEditedNote()
                        raw 'Approve'
                  else
                    child 'p', =>
                      raw 'This note is only visible to you until an administrator approves it.'
                if user_id is parseInt(note.user_id) or user_id in owners
                  if confirm_delete
                    child 'p', =>
                      raw 'Are you sure you want to delete this note? '
                      child 'button', =>
                        props
                          type: 'button'
                          onClick: =>
                            @props.aris.call 'notes.deleteNote',
                              note_id: note.note_id
                            , @successAt 'deleting this note', =>
                              @setState modal: nothing: {}
                              @search()
                        raw 'Delete'
                      raw ' '
                      child 'button', =>
                        props
                          type: 'button'
                          onClick: =>
                            @updateState modal: viewing_note: confirm_delete: $set: false
                        raw 'Cancel'
                  else
                    child 'p', =>
                      child 'button', =>
                        props
                          type: 'button'
                          onClick: =>
                            @updateState modal: viewing_note: confirm_delete: $set: true
                        raw 'Delete Note'
              child 'hr'
              if comments?
                comments.forEach (comment) =>
                  child 'div', key: comment.comment_id, =>
                    child 'h4', =>
                      raw "#{comment.user.display_name} at #{comment.created.toLocaleString()}"
                    if edit_comment_id is comment.comment_id
                      child 'p', =>
                        child 'textarea', =>
                          props
                            placeholder: 'Edit your comment...'
                            value: edit_comment_text
                            onChange: (e) => @updateState modal: viewing_note: edit_comment_text: $set: e.target.value
                            style:
                              width: '100%'
                              height: 100
                      child 'p', =>
                        child 'button', =>
                          props
                            type: 'button'
                            onClick: =>
                              if edit_comment_text isnt ''
                                @props.aris.updateNoteComment
                                  note_comment_id: comment.comment_id
                                  description: edit_comment_text
                                , @successAt 'editing your comment', (comment) =>
                                  @fetchComments note
                                  @updateState modal: viewing_note: edit_comment_id: $set: null
                          raw 'Save Comment'
                        raw ' '
                        child 'button', =>
                          props
                            type: 'button'
                            onClick: => @updateState modal: viewing_note: edit_comment_id: $set: null
                          raw 'Cancel'
                    else
                      child 'p', => raw comment.description
                      if @state.login_status.logged_in?
                        user_id = @state.login_status.logged_in.auth.user_id
                        owners =
                          owner.user_id for owner in @props.game.owners
                        child 'p', =>
                          if user_id is comment.user.user_id or user_id in owners
                            if confirm_delete_comment_id is comment.comment_id
                              raw 'Are you sure you want to delete this comment? '
                              child 'button', =>
                                props
                                  type: 'button'
                                  onClick: =>
                                    @props.aris.call 'note_comments.deleteNoteComment',
                                      note_comment_id: comment.comment_id
                                    , @successAt 'deleting this comment', =>
                                      @updateState modal: viewing_note: confirm_delete_comment_id: $set: null
                                      @fetchComments note
                                raw 'Delete'
                              raw ' '
                              child 'button', =>
                                props
                                  type: 'button'
                                  onClick: =>
                                    @updateState modal: viewing_note: confirm_delete_comment_id: $set: null
                                raw 'Cancel'
                            else
                              raw ' '
                              child 'button', =>
                                props
                                  type: 'button'
                                  onClick: =>
                                    @updateState modal: viewing_note: confirm_delete_comment_id: $set: comment.comment_id
                                raw 'Delete Comment'
                          if user_id is comment.user.user_id
                              raw ' '
                              child 'button', =>
                                props
                                  type: 'button'
                                  onClick: =>
                                    @updateState modal: viewing_note:
                                      edit_comment_id: $set: comment.comment_id
                                      edit_comment_text: $set: comment.description
                                raw 'Edit Comment'
              else
                child 'p', => raw 'Loading comments...'
              if @state.login_status.logged_in?
                child 'div', =>
                  child 'textarea', =>
                    props
                      placeholder: 'Post a new comment...'
                      value: new_comment
                      onChange: (e) => @updateState modal: viewing_note: new_comment: $set: e.target.value
                      style:
                        width: '100%'
                        height: 100
                  child 'p', =>
                    child 'button', =>
                      props
                        type: 'button'
                        onClick: =>
                          if new_comment isnt ''
                            @props.aris.createNoteComment
                              game_id: @props.game.game_id
                              note_id: note.note_id
                              description: new_comment
                            , @successAt 'posting your comment', (comment) =>
                              @fetchComments note
                              @updateState modal: viewing_note: new_comment: $set: ''
                      raw 'Submit'
              else
                child 'p', =>
                  child 'b', =>
                    props
                      onClick: => @setState account_menu: true
                      style: cursor: 'pointer'
                    raw 'Login'
                  raw ' to post a new comment'
        select_photo: ({file}) =>
          child 'div.primaryModal', =>
            props style: backgroundColor: 'white'
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#cfcbcc'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: => @setState modal: nothing: {}
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'CANCEL'
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: =>
                  if file?
                    name = file.name
                    ext = name[name.indexOf('.') + 1 ..]
                    @setState modal: uploading_photo: progress: 0
                    $.ajax
                      url: "#{ARIS_URL}/rawupload.php"
                      type: 'POST'
                      xhr: =>
                        xhr = new window.XMLHttpRequest
                        xhr.upload.addEventListener 'progress', (evt) =>
                          if evt.lengthComputable
                            @updateState modal: uploading_photo: progress: $set: evt.loaded / evt.total
                        , false
                        xhr
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
                                enter_description:
                                  media: media
                                  tag: @props.game.tags[0]
                                  description: ''
                              message: null
                      error: (jqXHR, textStatus, errorThrown) =>
                        @setState message:
                          """
                          There was a problem uploading your photo. Please report this error:
                          #{JSON.stringify [jqXHR, textStatus, errorThrown]}
                          """
                      data: do =>
                        form = new FormData
                        form.append 'raw_upload', file
                        form
                      cache: false
                      contentType: false
                      processData: false
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'DESCRIPTION >'
            if file?
              child 'div', =>
                props
                  style:
                    position: 'absolute'
                    top: '25%'
                    left: '25%'
                    height: '50%'
                    width: '50%'
                    backgroundImage: "url(#{URL.createObjectURL file})"
                    backgroundSize: 'contain'
                    backgroundRepeat: 'no-repeat'
                    backgroundPosition: 'center'
                    cursor: 'pointer'
                  onClick: => @refs.file_input.click()
            else
              child 'img', =>
                props
                  src: 'img/select-image.png'
                  style:
                    position: 'absolute'
                    top: 'calc(50% - 56px)'
                    left: 'calc(50% - 69.5px)'
                    cursor: 'pointer'
                  onClick: => @refs.file_input.click()
            child 'form', =>
              props ref: 'file_form', style: {position: 'fixed', left: 9999}
              child 'input', =>
                props
                  type: 'file', accept: 'image/*', capture: 'camera', name: 'raw_upload', ref: 'file_input'
                  onChange: (e) =>
                    if (newFile = e.target.files[0])?
                      @updateState modal: select_photo: file: $set: newFile
        uploading_photo: ({progress}) =>
          child 'div.primaryModal', style: {backgroundColor: 'white'}, =>
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#cfcbcc'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: => @setState modal: nothing: {}
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'CANCEL'
            child 'p', =>
              props style: {position: 'absolute', top: '50%', width: '100%', textAlign: 'center'}
              raw "Uploading... (#{Math.floor(progress * 100)}%)"
        enter_description: ({media, description}) =>
          child 'div.bottomModal', style: {height: 250}, =>
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: => @setState modal: select_photo: {}
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw '< IMAGE'
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: =>
                  if description is ''
                    @setState message: 'Please type a caption for your photo.'
                  else
                    @updateState
                      latitude: $set: @props.game.latitude
                      longitude: $set: @props.game.longitude
                      zoom: $set: @props.game.zoom
                      modal:
                        $apply: ({enter_description}) =>
                          if 'geolocation' of navigator
                            navigator.geolocation.getCurrentPosition (posn) =>
                              @setState (previousState) =>
                                if previousState.modal.move_point?.can_reposition
                                  update previousState,
                                    modal: move_point:
                                      latitude: $set: posn.coords.latitude
                                      longitude: $set: posn.coords.longitude
                                    latitude: $set: posn.coords.latitude
                                    longitude: $set: posn.coords.longitude
                                else
                                  previousState
                          move_point:
                            update enter_description,
                              latitude: $set: @props.game.latitude
                              longitude: $set: @props.game.longitude
                              dragging: $set: false
                              can_reposition: $set: true
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'LOCATION >'
            child 'img', =>
              props
                src: 'img/x-blue.png'
                style:
                  position: 'absolute'
                  top: 20
                  right: 20
                  cursor: 'pointer'
                onClick: => @setState modal: nothing: {}
            child 'textarea', =>
              props
                style:
                  position: 'absolute'
                  top: 20
                  left: 20
                  width: 'calc(100% - 86px)'
                  height: 'calc(100% - 100px)'
                  fontSize: '20px'
                value: description
                placeholder: 'Enter a caption...'
                onChange: (e) =>
                  @updateState modal: enter_description: description: $set: e.target.value
        move_point: ({media, description, latitude, longitude}) =>
          child 'div.bottomModal', style: {height: 150}, =>
            child 'p', =>
              props
                style:
                  width: '100%'
                  textAlign: 'center'
                  top: 30
                  position: 'absolute'
              raw 'Drag the map to drop a pin'
            child 'img', =>
              props
                src: 'img/x-blue.png'
                style:
                  position: 'absolute'
                  top: 20
                  right: 20
                  cursor: 'pointer'
                onClick: => @setState modal: nothing: {}
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: =>
                  @setState modal: enter_description: {media, description}
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw '< DESCRIPTION'
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: =>
                  @updateState
                    modal:
                      $apply: ({move_point}) =>
                        select_category:
                          update move_point,
                            tag: $set: @props.game.tags[0]
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'CATEGORY >'
        select_category: ({media, description, latitude, longitude, tag}) =>
          child 'div.bottomModal', style: {height: 200}, =>
            child 'div', =>
              props style: {width: '100%', textAlign: 'center', top: 30, position: 'absolute'}
              child 'p', => raw 'Select a Category'
              child 'p', =>
                @props.game.tags.forEach (some_tag) =>
                  checked = some_tag is tag
                  color = @props.game.colors["tag_#{tag_ids.indexOf(some_tag.tag_id) + 1}"] ? 'black'
                  child 'span', =>
                    props
                      key: some_tag.tag_id
                      style:
                        margin: 5
                        padding: 5
                        border: "1px solid #{color}"
                        color: if checked then 'white' else color
                        backgroundColor: if checked then color else 'white'
                        borderRadius: 5
                        cursor: 'pointer'
                        whiteSpace: 'nowrap'
                        display: 'inline-block'
                      onClick: => @updateState modal: select_category: tag: $set: some_tag
                    raw "#{if checked then '✓' else '●'} #{some_tag.tag}"
            child 'img', =>
              props
                src: 'img/x-blue.png'
                style: {position: 'absolute', top: 20, right: 20, cursor: 'pointer'}
                onClick: => @setState modal: nothing: {}
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: => @setState modal: move_point: {media, description, latitude, longitude}
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw '< LOCATION'
            child 'div', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  cursor: 'pointer'
                  height: 36
                  backgroundColor: '#61c9e2'
                  color: 'white'
                  display: 'table'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                onClick: =>
                  @props.aris.call 'notes.createNote',
                    game_id: @props.game.game_id
                    description: description
                    media_id: media.media_id
                    trigger: {latitude, longitude}
                    tag_id: tag.tag_id
                  , @successAt 'creating your note', (note) =>
                    @setState modal: nothing: {} # TODO: fetch and view note
                    @search()
              child 'div', =>
                props
                  style:
                    display: 'table-cell'
                    verticalAlign: 'middle'
                    paddingLeft: 23
                    paddingRight: 23
                    width: '100%'
                    height: '100%'
                    boxSizing: 'border-box'
                raw 'PUBLISH! >'

      # Message box (for errors)
      if @state.message?
        child 'div', =>
          props style: {position: 'fixed', left: 100, width: 'calc(100% - 300px)', top: 'calc(50% - 50px)', backgroundColor: 'black', color: 'white', textAlign: 'center', padding: 50}
          raw @state.message
          child 'div', =>
            props
              style: {position: 'absolute', left: 10, top: 10, cursor: 'pointer'}
              onClick: => @setState message: null
            raw 'X'

      # Mobile title and hamburger menu button
      child 'div.mobileTitle', =>
        child 'span.hamburgerButton', =>
          props
            style: cursor: 'pointer'
            onClick: => @setState account_menu: not @state.account_menu
          raw '☰'
        raw ' '
        raw @props.game.name

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

                ReactDOM.render React.createElement(App, game: game, aris: aris), document.getElementById('the-container')

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
