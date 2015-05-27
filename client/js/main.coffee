class Game
  constructor: (json) ->
    @game_id   = parseInt json.game_id
    @name      = json.name
    @latitude  = parseFloat json.map_latitude
    @longitude = parseFloat json.map_longitude
    @zoom      = parseInt json.map_zoom_level

class User
  constructor: (json) ->
    @user_id      = parseInt json.user_id
    @display_name = json.display_name or json.user_name

class Tag
  constructor: (json) ->
    @icon_url = json.media?.data?.url
    @tag      = json.tag
    @tag_id   = parseInt json.tag_id

class Comment
  constructor: (json) ->
    @description = json.description
    @comment_id  = parseInt json.note_comment_id
    @user        = new User json.user
    @created     = new Date(json.created.replace(' ', 'T') + 'Z')

class Note
  constructor: (json) ->
    @user         = new User json.user
    @description  = json.description
    @photo_url    =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.url
    @thumb_url =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.thumb_url
    @latitude     = parseFloat json.latitude
    @longitude    = parseFloat json.longitude
    @tag_id       = parseInt json.tag_id
    @created      = new Date(json.created.replace(' ', 'T') + 'Z')
    @player_liked = parseInt(json.player_liked) isnt 0
    @note_likes   = parseInt json.note_likes
    @comments     =
      new Comment o for o in json.comments.data

class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris
      @login undefined, undefined, =>
        @siftr_url = 'snowchallenge' # for testing
        @siftr_id = null
        @getGameInfo =>
          @getGameOwners =>
            @createMap()
            @getGameTags =>
              @makeTagLists()
              @performSearch =>
                @installListeners()

  getGameInfo: (cb) ->
    if @siftr_url?
      @aris.call 'games.searchSiftrs',
        siftr_url: @siftr_url
      , ({data: games, returnCode}) =>
        if returnCode is 0 and games.length is 1
          @game = new Game games[0]
          $('#the-siftr-title').text @game.name
          cb()
        else
          @error "Failed to retrieve the Siftr game info"
    else if @siftr_id?
      @aris.call 'games.getGame',
        game_id: @siftr_id
      , ({data: game, returnCode}) =>
        @game = new Game game
        $('#the-siftr-title').text @game.name
        cb()
    else
      @error "No Siftr specified"

  getGameOwners: (cb) ->
    @aris.call 'users.getUsersForGame',
      game_id: @game.game_id
    , ({data: owners, returnCode}) =>
      if returnCode is 0
        @game.owners =
          new User o for o in owners
        if @game.owners.length > 0
          names =
            user.display_name for user in @game.owners
          commaList = (list) -> switch list.length
            when 0 then ""
            when 1 then list[0]
            else        "#{list[0..-2].join(', ')} and #{list[list.length - 1]}"
          $('#the-siftr-subtitle').text "Started by #{commaList names}"
      else
        @game.owners = []
        @warn "Failed to retrieve the list of Siftr owners"
      cb()

  # http://stackoverflow.com/a/10722973
  centerMapOffset: (latlng = @map.getCenter(), offsetx = 0, offsety = 0) ->
    p1 = @map.getProjection().fromLatLngToPoint latlng
    z = @map.getZoom()
    p2 = new google.maps.Point(offsetx / (2 ** z), offsety / (2 ** z))
    @map.setCenter do =>
      @map.getProjection().fromPointToLatLng do =>
        new google.maps.Point(p1.x - p2.x, p1.y - p2.y)

  setMapCenter: (latlng) ->
    w = $('body').width()
    if w < 907
      @map.setCenter latlng
    else
      offsetx = (w - 450 - 30) / 2 - w / 2
      if @map.getProjection()?
        @centerMapOffset latlng, offsetx, 0
      else
        listener = google.maps.event.addListener @map, 'projection_changed', =>
          if @map.getProjection()?
            @centerMapOffset latlng, offsetx, 0
            google.maps.event.removeListener listener

  createMap: ->
    @mapCenter = new google.maps.LatLng @game.latitude, @game.longitude
    @map = new google.maps.Map $('#the-map')[0],
      zoom: @game.zoom
      center: @mapCenter
      mapTypeId: google.maps.MapTypeId.ROADMAP
      panControl: false
      zoomControl: false
      mapTypeControl: false
      scaleControl: false
      streetViewControl: false
      overviewMapControl: false
      styles: window.mapStyle.concat
        featureType: 'poi'
        elementType: 'labels'
        stylers: [{visibility: 'off'}]
    @setMapCenter @mapCenter
    @dragMarker = new google.maps.Marker
      position: @mapCenter
      map: null # hidden at first
      draggable: true
      zIndexProcess: -> 9999

  getGameTags: (cb) ->
    @aris.call 'tags.getTagsForGame',
      game_id: @game.game_id
    , ({data: tags, returnCode}) =>
      if returnCode is 0
        @game.tags =
          new Tag o for o in tags
        cb()
      else
        @error "Failed to retrieve the list of tags"

  makeTagLists: ->
    appendTo $('#the-search-tags'), 'form', {}, (form) =>
      for t in @game.tags
        appendTo form, 'p', {}, (p) =>
          appendTo p, 'label', {}, (label) =>
            appendTo label, 'input',
              type: 'checkbox'
              checked: false
              value: t.tag_id
            label.append document.createTextNode t.tag
    appendTo $('#the-tag-assigner'), 'form', {}, (form) =>
      for t, i in @game.tags
        appendTo form, 'p', {}, (p) =>
          appendTo p, 'label', {}, (label) =>
            appendTo label, 'input',
              type: 'radio'
              checked: i is 0
              name: 'upload-tag'
              value: t.tag_id
            label.append document.createTextNode t.tag

  performSearch: (cb) ->
    thisSearch = @lastSearch = Date.now()
    tag_ids =
      for box in $('#the-search-tags input[type="checkbox"]')
        continue unless box.checked
        parseInt box.value
    @aris.call 'notes.searchNotes',
      game_id: @game.game_id
      tag_ids: tag_ids
      order_by: 'recent'
      # TODO: search
    , ({data: notes, returnCode}) =>
      if returnCode is 0
        if thisSearch is @lastSearch
          @game.notes =
            new Note o for o in notes
          # hide notes that don't have photos
          @game.notes =
            n for n in @game.notes when n.photo_url?
          @updateGrid()
          @updateMap()
        cb()
      else
        @error "Failed to search for notes"

  updateGrid: ->
    $('#the-note-grid').html ''
    grid = $('#the-note-grid')
    tr = null
    for note, i in @game.notes
      do (note) =>
        if i % 3 is 0
          tr = appendTo grid, '.a-grid-row'
        td = appendTo tr, '.a-grid-photo',
          style:
            if note.thumb_url?
              "background-image: url(\"#{note.thumb_url}\");"
            else
              "background-color: black;"
          alt: note.description
        td.click => @showNote note

  updateMap: ->
    if @markers?
      marker.setMap(null) for marker in @markers
    @markers =
      for note in @game.notes
        do (note) =>
          marker = new google.maps.Marker
            position: new google.maps.LatLng note.latitude, note.longitude
            map: @map
          google.maps.event.addListener marker, 'click', => @showNote note
          note.marker = marker
          marker

  showNote: (note) ->
    @scrollBackTo = $('#the-modal-content').scrollTop()
    @setMode 'note'
    $('#the-photo').css 'background-image',
      if note.photo_url?
        "url(\"#{note.photo_url}\")"
      else
        ''
    $('#the-photo-link').prop 'href', note.photo_url
    $('#the-photo-caption').text note.description
    $('#the-photo-credit').html """
      Created by <b>#{escapeHTML note.user.display_name}</b> at #{escapeHTML note.created.toLocaleString()}
    """
    $('#the-comments').html ''
    if note.comments.length > 0
      appendTo $('#the-comments'), 'h3', text: 'Comments'
      for comment in note.comments
        if comment.description.match(/\S/)
          appendTo $('#the-comments'), 'div', {}, (div) =>
            appendTo div, 'h4', text:
              "#{comment.user.display_name} (#{comment.created.toLocaleString()})"
            appendTo div, 'p', text: comment.description
    $('#the-modal-content').scrollTop 0

  setMode: (mode) ->
    body = $('body')
    oldMode = @mode
    @mode = mode
    body.removeClass 'is-open-menu'
    @dragMarker.setMap null
    switch mode
      when 'grid'
        @topMode = 'grid'
        body.removeClass 'is-mode-note'
        body.removeClass 'is-mode-add'
        body.removeClass 'is-mode-map'
        if @scrollBackTo?
          $('#the-modal-content').scrollTop @scrollBackTo
          delete @scrollBackTo
      when 'map'
        @topMode = 'map'
        body.removeClass 'is-mode-note'
        body.removeClass 'is-mode-add'
        body.addClass 'is-mode-map'
      when 'note'
        body.addClass 'is-mode-note'
        body.removeClass 'is-mode-add'
        body.removeClass 'is-mode-map'
      when 'add'
        body.removeClass 'is-mode-note'
        body.addClass 'is-mode-add'
        body.removeClass 'is-mode-map'
        @dragMarker.setMap @map
        @dragMarker.setPosition @mapCenter
        @dragMarker.setAnimation google.maps.Animation.DROP
        @setMapCenter @mapCenter
        @map.setZoom @game.zoom
        $('#the-caption-box').val ''
        $('#the-tag-assigner input[name=upload-tag]:first').click()
        if oldMode isnt 'add'
          for note in @game.notes
            note.marker.setOpacity 0.3
    if oldMode is 'add' and mode isnt 'add'
      for note in @game.notes
        note.marker.setOpacity 1

  submitNote: ->
    unless @ext? and @base64?
      @error 'Please select a photo to upload.'
      return
    desc = $('#the-caption-box').val()
    if desc.length is 0
      @error 'Please enter a caption for the image.'
      return
    @aris.call 'notes.createNote',
      game_id: @game.game_id
      media:
        file_name: "upload.#{@ext}"
        data: @base64
        resize: 640
      description: desc
      trigger:
        latitude: @dragMarker.getPosition().lat()
        longitude: @dragMarker.getPosition().lng()
      tag_id: parseInt $('#the-tag-assigner input[name=upload-tag]:checked').val()
    , ({data: simpleNote, returnCode}) =>
      if returnCode isnt 0
        @error 'There was an error uploading your photo.'
        return
      @aris.call 'notes.searchNotes',
        game_id: @game.game_id
        note_id: parseInt simpleNote.note_id
        note_count: 1
      , ({data: notes, returnCode}) =>
        if returnCode isnt 0
          @error 'There was an error retrieving your new photo.'
          return
        note = new Note notes[0]
        @game.notes.unshift note
        @updateGrid()
        @updateMap()
        @showNote note

  installListeners: ->
    body = $('body')
    @setMode 'grid'
    $('#the-user-logo, #the-menu-button').click =>
      body.toggleClass 'is-open-menu'
    $('#the-grid-button').click => @setMode 'grid'
    $('#the-map-button').click => @setMode 'map'
    $('#the-add-button').click =>
      if @mode is 'add'
        @setMode @topMode
      else if @aris.auth?
        @setMode 'add'
        @readyFile null
      else
        body.addClass 'is-open-menu'
    $('#the-icon-bar-x, #the-add-cancel-button').click =>
      @setMode @topMode
    $('#the-logout-button').click =>
      @logout()
      body.removeClass 'is-open-menu'
      @setMode @topMode
      @performSearch(=>)
    $('#the-tag-button').click =>
      if @mode is 'map'
        body.addClass 'is-open-tags'
      else
        body.toggleClass 'is-open-tags'
      @setMode 'grid'
      $('#the-modal-content').scrollTop 0
    $('#the-search-tags input[type="checkbox"]').change =>
      @performSearch(=>)
    $('#the-add-submit-button').click => @submitNote()
    # login form
    $('#the-login-button').click =>
      @login $('#the-username-input').val(), $('#the-password-input').val(), =>
        if @aris.auth?
          body.removeClass 'is-open-menu'
          @performSearch(=>)
    $('#the-username-input, #the-password-input').keypress (e) =>
      if e.which is 13
        $('#the-login-button').click()
        return false
    # drag and drop support for photo upload box
    $('#the-photo-upload-box').on 'dragover dragenter', (e) => false
    $('#the-photo-upload-box').on 'drop', (e) =>
      if xfer = e.originalEvent.dataTransfer
        if xfer.files.length
          @readyFile xfer.files[0]
          return false
    # click support for photo upload box
    $('#the-photo-upload-box').click =>
      $('#the-hidden-file-input').click()
    $('#the-hidden-file-input').on 'change', =>
      @readyFile $('#the-hidden-file-input')[0].files[0]

  readyFile: (file) ->
    delete @ext
    delete @base64
    $('#the-photo-upload-box').css 'background-image', ''
    if file?
      reader = new FileReader()
      reader.onload = (e) =>
        dataURL = e.target.result
        typeMap =
          jpg: 'image/jpeg'
          png: 'image/png'
          gif: 'image/gif'
        for ext, mime of typeMap
          prefix = "data:#{mime};base64,"
          if dataURL.substring(0, prefix.length) is prefix
            @ext    = ext
            @base64 = dataURL.substring(prefix.length)
            $('#the-photo-upload-box').css 'background-image', "url(\"#{dataURL}\")"
            break
      reader.readAsDataURL file

  login: (name, pw, cb) ->
    @aris.login name, pw, =>
      if @aris.auth?
        $('body').addClass 'is-logged-in'
      else
        $('body').removeClass 'is-logged-in'
      cb()

  logout: ->
    @aris.logout()
    $('body').removeClass 'is-logged-in'
    $('body').removeClass 'is-mode-add'

  error: (s) ->
    # TODO
    console.log "ERROR: #{s}"

  warn: (s) ->
    # TODO
    console.log "Warning: #{s}"

app = new App
window.app = app
