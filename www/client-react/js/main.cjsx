React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
# {markdown} = require 'markdown'
{Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} = require '../../shared/aris.js'
GoogleMap = require 'google-map-react'
{fitBounds} = require 'google-map-react/utils'
$ = require 'jquery'
{make, child, raw, props} = require '../../shared/react-writer.js'
EXIF = require '../../shared/exif.js'

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
    date_1: 'min'
    date_2: 'max'

  getColor: (x) ->
    if x instanceof Tag
      tag = x
    else if x.tag_id?
      tag = (tag for tag in @props.game.tags when tag.tag_id is parseInt(x.tag_id))[0]
    else if typeof x in ['number', 'string']
      tag = (tag for tag in @props.game.tags when tag.tag_id is parseInt x)[0]
    else
      return 'black'
    @props.game.colors["tag_#{@props.game.tags.indexOf(tag) + 1}"] ? 'black'

  updateState: (obj) ->
    @setState (previousState) =>
      update previousState, obj

  componentDidMount: ->
    @login()

  componentWillMount: ->
    @hashChanged()
    window.addEventListener 'hashchange', (=> @hashChanged()), false
    ['mouseup', 'touchend'].forEach (e) =>
      window.addEventListener e, =>
        if @dragListener?
          window.removeEventListener('mousemove', @dragListener)
          window.removeEventListener('touchmove', @dragListener)
          delete @dragListener
          @search()

  hashChanged: ->
    if md = window.location.hash.match /^#(\d+)$/
      note_id = parseInt md[1]
      alreadyViewing =
        if @state.modal.viewing_note?
          note_id is parseInt @state.modal.viewing_note.note.note_id
        else
          false
      unless alreadyViewing
        # fetch the right note and view it
        @props.aris.call 'notes.siftrSearch',
          game_id: @props.game.game_id
          note_id: note_id
          map_data: false
        , @successAt 'loading a note', (data) =>
          note = data.notes[0]
          @setState modal: viewing_note: note: note
          @fetchComments note
    else
      # Close any note views
      if @state.modal.viewing_note?
        @setState modal: nothing: {}

  handleMapChange: ({center: {lat, lng}, zoom, bounds: {nw, se}}) ->
    @search 0,
      latitude:      $set: lat
      longitude:     $set: lng
      zoom:          $set: zoom
      min_latitude:  $set: se.lat
      max_latitude:  $set: nw.lat
      min_longitude: $set: nw.lng
      max_longitude: $set: se.lng

  searchParams: (state = @state, logged_in = @state.login_status.logged_in?) ->
    unixTimeToString = (t) ->
      new Date(t).toISOString().replace('T', ' ').replace(/\.\d\d\dZ$/, '')
      # ISO string is in format "yyyy-mm-ddThh:mm:ss.sssZ"
      # we change it into "yyyy-mm-dd hh:mm:ss" for the ARIS SQL format
    switch state.date_1
      when 'min'
        min_time = undefined
        switch state.date_2
          when 'min'
            max_time = undefined # whatever
          when 'max'
            max_time = undefined
          else
            max_time = unixTimeToString state.date_2
      when 'max'
        max_time = undefined
        switch state.date_2
          when 'min'
            min_time = undefined
          when 'max'
            min_time = undefined # whatever
          else
            min_time = unixTimeToString state.date_2
      else
        switch state.date_2
          when 'min'
            min_time = undefined
            max_time = unixTimeToString state.date_1
          when 'max'
            min_time = unixTimeToString state.date_1
            max_time = undefined
          else
            min_time = unixTimeToString Math.min(state.date_1, state.date_2)
            max_time = unixTimeToString Math.max(state.date_1, state.date_2)
    game_id: @props.game.game_id
    min_latitude: state.min_latitude
    max_latitude: state.max_latitude
    min_longitude: state.min_longitude
    max_longitude: state.max_longitude
    zoom: state.zoom
    limit: 48
    order: state.order
    filter: if state.mine and logged_in then 'mine' else undefined
    tag_ids:
      tag_id for tag_id, checked of state.checked_tags when checked
    search: state.search
    min_time: min_time
    max_time: max_time

  search: (wait = 0, updater = {}, logged_in = @state.login_status.logged_in?) ->
    @setState (previousState) =>
      newState = update update(previousState, updater), page: {$set: 1}
      thisSearch = @lastSearch = Date.now()
      setTimeout =>
        return unless thisSearch is @lastSearch
        @props.aris.call 'notes.siftrSearch',
          @searchParams(newState, logged_in)
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
    params = update @searchParams(),
      offset: $set: (page - 1) * 48
      map_data: $set: false
    @props.aris.call 'notes.siftrSearch',
      params
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
          $apply: (modal) =>
            if modal.viewing_note?.note is note
              update modal,
                viewing_note:
                  comments: $set: data
            else
              modal

  refreshEditedNote: (note_id = @state.modal.viewing_note.note.note_id) ->
    @search()
    @props.aris.call 'notes.siftrSearch',
      game_id: @props.game.game_id
      note_id: note_id
      map_data: false
    , @successAt 'refreshing this note', (data) =>
      note = data.notes[0]
      @setState modal: viewing_note: note: note
      @fetchComments note

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
          @fetchUserPicture()

  fetchUserPicture: ->
    match @state.login_status,
      logged_out: => null
      logged_in: ({auth}) =>
        @props.aris.call 'media.getMedia',
          media_id: auth.media_id
        , @successAt 'fetching your user picture', (media) =>
          @updateState
            login_status:
              $apply: (status) =>
                if status.logged_in
                  logged_in:
                    auth: auth
                    media: media
                else
                  status

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
    hash =
      if @state.modal.viewing_note?
        "##{@state.modal.viewing_note.note.note_id}"
      else
        ""
    if window.location.hash isnt hash
      window.location.hash = hash

    make 'div#the-contained', =>
      props
        className: """
          #{if @state.search_controls? then 'searching' else 'notSearching'}
          #{if @state.account_menu then 'accountMenuOpen' else ''}
          #{if @state.view_focus is 'map' then 'primaryMap' else 'primaryThumbs'}
          """
        style:
          width: '100%'
          height: '100%'
          overflow: 'visible'

      # Map
      child 'div.theMap', ref: 'theMapDiv', =>
        child GoogleMap, =>
          props
            center: [@state.latitude, @state.longitude]
            zoom: Math.max 2, @state.zoom
            options: minZoom: 2
            draggable: true
            onChange: @handleMapChange
            options:
              styles:
                # from https://snazzymaps.com/style/83/muted-blue
                [{"featureType":"all","stylers":[{"saturation":0},{"hue":"#e7ecf0"}]},{"featureType":"road","stylers":[{"saturation":-70}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"water","stylers":[{"visibility":"simplified"},{"saturation":-60}]}]

          if @state.modal.move_point?
            child 'div', =>
              props
                lat: @state.latitude
                lng: @state.longitude
                style: {marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: 'white', border: '2px solid black'}
          else if @state.modal.select_category?
            modal = @state.modal.select_category
            color = @getColor modal.tag
            child 'div', =>
              props
                lat: modal.editing_note?.latitude ? modal.latitude
                lng: modal.editing_note?.longitude ? modal.longitude
                style: {marginLeft: '-7px', marginTop: '-7px', width: '14px', height: '14px', backgroundColor: color, border: '2px solid black'}
          else
            @state.map_notes.forEach (note) =>
              color = @getColor note
              hovering = @state.hover_note_id is note.note_id
              width = if hovering then 25 else 14
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
                  style: {marginLeft: -(width / 2), marginTop: -(width / 2), width: width, height: width, backgroundColor: color, border: '2px solid black', cursor: 'pointer'}
            for cluster, i in @state.map_clusters
              lat = cluster.min_latitude + (cluster.max_latitude - cluster.min_latitude) / 2
              lng = cluster.min_longitude + (cluster.max_longitude - cluster.min_longitude) / 2
              hovering = @state.hover_note_id? and @state.hover_note_id in cluster.note_ids
              width = if hovering then 30 else 20
              if -180 < lng < 180 && -90 < lat < 90
                do (cluster) =>
                  colors =
                    @getColor(tag_id) for tag_id of cluster.tags
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
                            width: @refs.theMapDiv.clientWidth * 0.9
                            height: @refs.theMapDiv.clientHeight * 0.9
                            # we shrink the stated map size a bit,
                            # to make sure we end up with some buffer around the points
                          {center, zoom} = fitBounds bounds, size
                          @setState
                            latitude: center.lat
                            longitude: center.lng
                            zoom: zoom
                      style: {marginLeft: -(width / 2), marginTop: -(width / 2), width: width, height: width, border: '2px solid black', background: gradient, color: 'black', cursor: 'pointer', textAlign: 'center', display: 'table', fontWeight: 'bold'}
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

        minTimeSlider = @props.game.created.getTime()
        maxTimeSlider = Date.now()
        getTime = (t) -> switch t
          when 'min' then minTimeSlider
          when 'max' then maxTimeSlider
          else            t
        time1Fraction = (getTime(@state.date_1) - minTimeSlider) / (maxTimeSlider - minTimeSlider)
        time2Fraction = (getTime(@state.date_2) - minTimeSlider) / (maxTimeSlider - minTimeSlider)
        child 'div', =>
          minTime = getTime @state.date_1
          maxTime = getTime @state.date_2
          if minTime > maxTime
            [minTime, maxTime] = [maxTime, minTime]
          child 'span', style: {float: 'left'}, =>
            raw new Date(minTime).toLocaleDateString()
          child 'span', style: {float: 'right'}, =>
            raw new Date(maxTime).toLocaleDateString()
          child 'div', style: {clear: 'both'}
        child 'div', =>
          child 'div', =>
            props
              ref: 'timeSlider'
              style:
                height: 10
                width: '100%'
                backgroundColor: '#888'
                marginTop: 10
                marginBottom: 10
                position: 'relative'
            [false, true].forEach (isSlider1) =>
              child 'div', =>
                pointerDown = (movement) => (e) =>
                  unless @dragListener?
                    @dragListener = (e) =>
                      rect = @refs.timeSlider.getBoundingClientRect()
                      switch movement
                        when 'mousemove'
                          frac = (e.clientX - (rect.left + 10)) / (rect.width - 20)
                        when 'touchmove'
                          frac = (e.touches[0].clientX - (rect.left + 10)) / (rect.width - 20)
                      frac = Math.max(0, Math.min(1, frac))
                      encodedTime = switch frac
                        when 0 then 'min'
                        when 1 then 'max'
                        else minTimeSlider + (maxTimeSlider - minTimeSlider) * frac
                      if isSlider1
                        @setState
                          date_1: encodedTime
                      else
                        @setState
                          date_2: encodedTime
                    window.addEventListener movement, @dragListener
                props
                  style:
                    height: 20
                    width: 20
                    backgroundColor: '#444'
                    position: 'absolute'
                    top: -5
                    left: "calc((100% - 20px) * #{if isSlider1 then time1Fraction else time2Fraction})"
                    borderRadius: 4
                    cursor: 'pointer'
                  onMouseDown: pointerDown 'mousemove'
                  onTouchStart: pointerDown 'touchmove'

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
            color = @getColor tag
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
      child 'div.theThumbs', =>
        props
          style: {overflowY: 'scroll', textAlign: 'center', backgroundColor: 'white'}

        if @state.page isnt 1
          child 'div.blueButton', =>
            props
              style:
                padding: 15
                boxSizing: 'border-box'
              onClick: => @setPage(@state.page - 1)
            raw 'Previous Page'

        @state.notes.forEach (note) =>
          child 'div.thumbnail', =>
            props
              key: note.note_id
              style:
                backgroundImage: "url(#{note.media.thumb_url})"
                backgroundSize: '100% 100%'
                margin: 5
                cursor: 'pointer'
                position: 'relative'
                display: 'inline-block'
              onMouseOver: =>
                @setState
                  hover_note_id: note.note_id
              onMouseOut: =>
                if @state.hover_note_id?
                  @setState hover_note_id: null
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
            child 'div',
              style:
                position: 'absolute'
                right: 5
                top: 5
                width: 14
                height: 14
                borderRadius: 7
                backgroundColor: @getColor note

        if @state.notes.length is 48
          child 'div.blueButton', =>
            props
              style:
                padding: 15
                boxSizing: 'border-box'
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

        child 'div.menuDiscover.menuTable', =>
          child 'a.menuTableCell', href: '..', =>
            raw 'DISCOVER'

        child 'div.menuMyAccount.menuTable', =>
          child 'div.menuTableCell', =>
            props onClick: => @setState account_menu: not @state.account_menu
            raw 'MY ACCOUNT'

        child 'div.menuMySiftrs.menuTable', =>
          child 'a.menuTableCell', href: '../editor', =>
            raw 'MY SIFTRS'

      # Desktop and mobile add buttons
      clickAdd = =>
        if @state.login_status.logged_in?
          @setState modal: select_photo: {}
        else
          @setState account_menu: true
      if @state.search_controls is null and (@state.modal.nothing? or @state.modal.viewing_note?)
        child 'div.addItemDesktop', =>
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
            right: 120
            backgroundColor: 'rgb(44,48,59)'
            color: 'white'
            paddingLeft: 10
            paddingRight: 10
            width: 275
        match @state.login_status,
          logged_out: ({username, password}) =>
            child 'div', =>
              child 'p', style: {textAlign: 'center'}, =>
                raw 'Login to your Siftr or ARIS account'
              child 'p', =>
                props style: {width: '100%'}
                usernameBox username, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                props style: {width: '100%'}
                passwordBox password, width: '100%', boxSizing: 'border-box'
              child 'div.blueButton', =>
                props
                  style:
                    width: '100%'
                    boxSizing: 'border-box'
                    textAlign: 'center'
                    cursor: 'pointer'
                    padding: 5
                    marginBottom: 12
                  onClick: @login
                raw 'LOGIN'
          logged_in: ({auth, media}) =>
            child 'div', style: {textAlign: 'center'}, =>
              child 'p', =>
                child 'span', style:
                  width: 100
                  height: 100
                  borderRadius: 50
                  backgroundColor: 'white'
                  backgroundImage: if media? then "url(#{media.thumb_url})" else undefined
                  backgroundSize: 'cover'
                  display: 'inline-block'
              child 'p', =>
                raw auth.display_name
              child 'div.blueButton', =>
                props
                  style:
                    width: '100%'
                    boxSizing: 'border-box'
                    textAlign: 'center'
                    cursor: 'pointer'
                    padding: 5
                    marginBottom: 12
                  onClick: @logout
                raw 'LOGOUT'

      # Mobile account menu
      child 'div.accountMenuMobile', =>
        props
          style:
            backgroundColor: 'rgb(32,37,49)'
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
              child 'p', style: {textAlign: 'center'}, =>
                raw 'Login to your Siftr or ARIS account'
              child 'p', =>
                props style: {width: '100%'}
                usernameBox username, width: '100%', boxSizing: 'border-box'
              child 'p', =>
                props style: {width: '100%'}
                passwordBox password, width: '100%', boxSizing: 'border-box'
              child 'div.blueButton', =>
                props
                  style:
                    width: '100%'
                    boxSizing: 'border-box'
                    textAlign: 'center'
                    cursor: 'pointer'
                    padding: 5
                    marginBottom: 12
                  onClick: @login
                raw 'LOGIN'
          logged_in: ({auth, media}) =>
            child 'div', style: {textAlign: 'center'}, =>
              child 'p', =>
                child 'span', style:
                  width: 80
                  height: 80
                  borderRadius: 40
                  backgroundColor: 'white'
                  backgroundImage: if media? then "url(#{media.thumb_url})" else undefined
                  backgroundSize: 'cover'
                  display: 'inline-block'
              child 'p', =>
                raw auth.display_name
              child 'p', =>
                child 'img', src: 'img/brand-mobile.png'
              unlink =
                color: 'white'
                textDecoration: 'none'
              child 'p', => child 'a', style: unlink, href: '../editor', => raw 'My Siftrs'
              child 'p', => child 'a', style: unlink, href: '..', => raw 'Discover'
              child 'p', style: {cursor: 'pointer'}, onClick: @logout, => raw 'Logout'
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
              child 'h4', =>
                props
                  style:
                    width: 'calc(100% - 80px)'
                raw "#{note.display_name} at #{new Date(note.created.replace(' ', 'T') + 'Z').toLocaleString()}"
              child 'img', =>
                props
                  src: note.media.url
                  style:
                    width: '100%'
                    display: 'block'
              user_id =
                if @state.login_status.logged_in?
                  @state.login_status.logged_in.auth.user_id
                else
                  null
              owners =
                owner.user_id for owner in @props.game.owners
              child 'div', =>
                props
                  style:
                    backgroundColor: 'rgb(97,201,226)'
                    width: '100%'
                    height: 50
                barButton = (img, action) =>
                  child 'img',
                    src: img
                    style:
                      marginTop: 9
                      marginLeft: 12
                      cursor: 'pointer'
                    onClick: action
                if user_id is parseInt(note.user_id) or user_id in owners
                  barButton 'img/freepik/delete81.png', =>
                    @updateState modal: viewing_note: confirm_delete: $set: true
                if user_id is parseInt(note.user_id)
                  barButton 'img/freepik/edit45.png', =>
                    @setState modal: enter_description:
                      editing_note: note
                      description: note.description
                  barButton 'img/freepik/location73.png', =>
                    @setState
                      modal:
                        move_point:
                          editing_note: note
                      latitude: parseFloat note.latitude
                      longitude: parseFloat note.longitude
                  barButton 'img/freepik/tag79.png', =>
                    @setState
                      modal:
                        select_category:
                          editing_note: note
                          tag: do =>
                            for tag in @props.game.tags
                              return tag if tag.tag_id is parseInt note.tag_id
                      latitude: parseFloat note.latitude
                      longitude: parseFloat note.longitude
              if @state.login_status.logged_in?
                if note.published is 'PENDING'
                  if user_id in owners
                    child 'p', => child 'b', => raw 'This note needs your approval to be visible.'
                    child 'p', =>
                      child 'span.blueButton', =>
                        props
                          style:
                            padding: 5
                          onClick: =>
                            @props.aris.call 'notes.approveNote',
                              note_id: note.note_id
                            , @successAt 'approving this note', => @refreshEditedNote()
                        raw 'APPROVE'
                  else
                    child 'p', => child 'b', =>
                      raw 'This note is only visible to you until an administrator approves it.'
                if confirm_delete
                  child 'p', => child 'b', => raw 'Are you sure you want to delete this note?'
                  child 'p', =>
                    child 'span.blueButton', =>
                      props
                        style:
                          padding: 5
                          marginRight: 10
                        onClick: =>
                          @props.aris.call 'notes.deleteNote',
                            note_id: note.note_id
                          , @successAt 'deleting this note', =>
                            @setState modal: nothing: {}
                            @search()
                      raw 'DELETE'
                    child 'span.blueButton', =>
                      props
                        style:
                          padding: 5
                        onClick: =>
                          @updateState modal: viewing_note: confirm_delete: $set: false
                      raw 'CANCEL'
              child 'p', => raw note.description
              child 'hr'
              if comments?
                comments.forEach (comment) =>
                  child 'div', key: comment.comment_id, =>
                    child 'h4', =>
                      raw "#{comment.user.display_name} at #{comment.created.toLocaleString()} "
                      if user_id is comment.user.user_id or user_id in owners
                        child 'img',
                          src: 'img/freepik/delete81_blue.png'
                          style: cursor: 'pointer'
                          onClick: =>
                            @updateState modal: viewing_note: confirm_delete_comment_id: $set: comment.comment_id
                      raw ' '
                      if user_id is comment.user.user_id
                        child 'img',
                          src: 'img/freepik/edit45_blue.png'
                          style: cursor: 'pointer'
                          onClick: =>
                            @updateState modal: viewing_note:
                              edit_comment_id: $set: comment.comment_id
                              edit_comment_text: $set: comment.description
                    if edit_comment_id is comment.comment_id
                      child 'p', =>
                        child 'textarea', =>
                          props
                            placeholder: 'Edit your comment...'
                            value: edit_comment_text
                            onChange: (e) => @updateState modal: viewing_note: edit_comment_text: $set: e.target.value
                            style:
                              width: '100%'
                              height: 75
                              resize: 'none'
                              boxSizing: 'border-box'
                      child 'p', =>
                        child 'span.blueButton', =>
                          props
                            style:
                              padding: 5
                              marginRight: 10
                            onClick: =>
                              if edit_comment_text isnt ''
                                @props.aris.updateNoteComment
                                  note_comment_id: comment.comment_id
                                  description: edit_comment_text
                                , @successAt 'editing your comment', (comment) =>
                                  @fetchComments note
                                  @updateState modal: viewing_note: edit_comment_id: $set: null
                          raw 'SAVE COMMENT'
                        child 'span.blueButton', =>
                          props
                            style:
                              padding: 5
                              marginRight: 10
                            onClick: => @updateState modal: viewing_note: edit_comment_id: $set: null
                          raw 'CANCEL'
                    else
                      if confirm_delete_comment_id is comment.comment_id
                        child 'p', => child 'b', => raw 'Are you sure you want to delete this comment?'
                        child 'p', =>
                          child 'span.blueButton', =>
                            props
                              style:
                                padding: 5
                                marginRight: 10
                              onClick: =>
                                @props.aris.call 'note_comments.deleteNoteComment',
                                  note_comment_id: comment.comment_id
                                , @successAt 'deleting this comment', =>
                                  @updateState modal: viewing_note: confirm_delete_comment_id: $set: null
                                  @fetchComments note
                            raw 'DELETE'
                          child 'span.blueButton', =>
                            props
                              style:
                                padding: 5
                              onClick: =>
                                @updateState modal: viewing_note: confirm_delete_comment_id: $set: null
                            raw 'CANCEL'
                      child 'p', => raw comment.description
              else
                child 'p', => raw 'Loading comments...'
              if @state.login_status.logged_in?
                child 'p', =>
                  child 'textarea', =>
                    props
                      placeholder: 'Post a new comment...'
                      value: new_comment
                      onChange: (e) => @updateState modal: viewing_note: new_comment: $set: e.target.value
                      style:
                        width: '100%'
                        height: 75
                        resize: 'none'
                        boxSizing: 'border-box'
                child 'p', =>
                  child 'span.blueButton', =>
                    props
                      style:
                        padding: 5
                        marginRight: 10
                      onClick: =>
                        if new_comment isnt ''
                          @props.aris.createNoteComment
                            game_id: @props.game.game_id
                            note_id: note.note_id
                            description: new_comment
                          , @successAt 'posting your comment', (comment) =>
                            @fetchComments note
                            @updateState modal: viewing_note: new_comment: $set: ''
                    raw 'POST COMMENT'
              else
                child 'p', =>
                  child 'span.blueButton', =>
                    props
                      style:
                        padding: 5
                        marginRight: 10
                      onClick: => @setState account_menu: true
                    raw 'LOGIN'
                  raw 'to post a new comment'
        select_photo: ({file, orientation}) =>
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
            child 'div.blueButton', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  height: 36
                  display: 'table'
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
                  className: "exif-#{orientation or 1}"
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
                  type: 'file', name: 'raw_upload', ref: 'file_input'
                  onChange: (e) =>
                    if (newFile = e.target.files[0])?
                      @updateState modal: select_photo:
                        file: $set: newFile
                        orientation: $set: 1
                      EXIF.getData newFile, =>
                        @updateState modal: select_photo: orientation: $set:
                          EXIF.getTag(newFile, 'Orientation') or 1
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
        enter_description: ({media, description, editing_note}) =>
          child 'div.bottomModal', style: {height: 250}, =>
            child 'div.blueButton', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  left: 20
                  height: 36
                  display: 'table'
                  boxSizing: 'border-box'
                onClick: => @setState modal: select_photo: {}
              unless editing_note?
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
            child 'div.blueButton', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  height: 36
                  display: 'table'
                  boxSizing: 'border-box'
                onClick: =>
                  if description is ''
                    @setState message: 'Please type a caption for your photo.'
                  else if editing_note?
                    @props.aris.call 'notes.updateNote',
                      note_id: editing_note.note_id
                      game_id: @props.game.game_id
                      description: description
                    , @successAt 'editing your note', => @refreshEditedNote editing_note.note_id
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
                if editing_note? then raw 'SAVE' else raw 'LOCATION >'
            child 'img', =>
              props
                src: 'img/x-blue.png'
                style:
                  position: 'absolute'
                  top: 20
                  right: 20
                  cursor: 'pointer'
                onClick: =>
                  if editing_note?
                    @setState modal: viewing_note: note: editing_note
                    @fetchComments editing_note
                  else
                    @setState modal: nothing: {}
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
        move_point: ({media, description, editing_note}) =>
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
                onClick: =>
                  if editing_note?
                    @setState modal: viewing_note: note: editing_note
                    @fetchComments editing_note
                  else
                    @setState modal: nothing: {}
            unless editing_note?
              child 'div.blueButton', =>
                props
                  style:
                    position: 'absolute'
                    bottom: 20
                    left: 20
                    height: 36
                    display: 'table'
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
            child 'div.blueButton', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  height: 36
                  display: 'table'
                  boxSizing: 'border-box'
                onClick: =>
                  if editing_note?
                    @props.aris.call 'notes.updateNote',
                      note_id: editing_note.note_id
                      game_id: @props.game.game_id
                      trigger:
                        latitude: @state.latitude
                        longitude: @state.longitude
                    , @successAt 'editing your note', => @refreshEditedNote editing_note.note_id
                  else
                    @updateState
                      modal:
                        $apply: ({move_point}) =>
                          select_category:
                            update move_point,
                              latitude: $set: @state.latitude
                              longitude: $set: @state.longitude
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
                if editing_note? then raw 'SAVE' else raw 'CATEGORY >'
        select_category: ({media, description, latitude, longitude, tag, editing_note}) =>
          child 'div.bottomModal', style: {paddingBottom: 55, paddingTop: 15}, =>
            child 'div', =>
              props style: {width: '100%', textAlign: 'center', top: 30}
              child 'p', => raw 'Select a Category'
              child 'p', =>
                @props.game.tags.forEach (some_tag) =>
                  checked = some_tag is tag
                  color = @getColor some_tag
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
                onClick: =>
                  if editing_note?
                    @setState modal: viewing_note: note: editing_note
                    @fetchComments editing_note
                  else
                    @setState modal: nothing: {}
            unless editing_note?
              child 'div.blueButton', =>
                props
                  style:
                    position: 'absolute'
                    bottom: 20
                    left: 20
                    height: 36
                    display: 'table'
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
            child 'div.blueButton', =>
              props
                style:
                  position: 'absolute'
                  bottom: 20
                  right: 20
                  height: 36
                  display: 'table'
                  boxSizing: 'border-box'
                onClick: =>
                  if editing_note?
                    @props.aris.call 'notes.updateNote',
                      note_id: editing_note.note_id
                      game_id: @props.game.game_id
                      tag_id: tag.tag_id
                    , @successAt 'editing your note', => @refreshEditedNote editing_note.note_id
                  else
                    @props.aris.call 'notes.createNote',
                      game_id: @props.game.game_id
                      description: description
                      media_id: media.media_id
                      trigger: {latitude, longitude}
                      tag_id: tag.tag_id
                    , @successAt 'creating your note', (note) => @refreshEditedNote note.note_id
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
                if editing_note? then raw 'SAVE' else raw 'PUBLISH! >'

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
