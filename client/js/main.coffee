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
    @display_name = json.display_name
    # Let's always use display_name, never user_name

class Tag
  constructor: (json) ->
    @icon_url = json.media.data.url
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
    @photo_url    = json.media.data.url
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
      @aris.login undefined, undefined, =>
        @siftr_url = 'snowchallenge' # for testing
        @getGameInfo =>
          @getGameOwners =>
            @createMap()
            @getGameTags =>
              @makeSearchTags()
              @performSearch =>
                @installListeners()

  getGameInfo: (cb) ->
    @aris.call 'games.searchSiftrs',
      siftr_url: @siftr_url
    , ({data: games, returnCode}) =>
      if returnCode is 0 and games.length is 1
        @game = new Game games[0]
        $('#the-siftr-title').text @game.name
        $('#the-siftr-subtitle').text 'Started by Wilhuff Tarkin'
        cb()
      else
        @error "Failed to retrieve the Siftr game info"

  getGameOwners: (cb) ->
    @aris.call 'users.getUsersForGame',
      game_id: @game.game_id
    , ({data: owners, returnCode}) =>
      if returnCode is 0
        @game.owners =
          new User o for o in owners
      else
        @game.owners = []
        @warn "Failed to retrieve the list of Siftr owners"
      cb()

  createMap: ->
    opts =
      zoom: @game.zoom
      center: new google.maps.LatLng @game.latitude, @game.longitude
      mapTypeId: google.maps.MapTypeId.ROADMAP
      panControl: false
      zoomControl: false
      mapTypeControl: false
      scaleControl: false
      streetViewControl: false
      overviewMapControl: false
      styles: window.mapStyle.concat [{
        featureType: 'poi'
        elementType: 'labels'
        stylers: [{visibility: 'off'}]
      }]
    @map = new google.maps.Map $('#the-map')[0], opts

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

  makeSearchTags: ->
    appendTo $('#the-search-tags'), 'form', {}, (form) =>
      for t in @game.tags
        appendTo form, 'p', {}, (p) =>
          appendTo p, 'label', {}, (label) =>
            appendTo label, 'input',
              type: 'checkbox'
              checked: false
            label.append document.createTextNode t.tag

  performSearch: (cb) ->
    @aris.call 'notes.searchNotes',
      game_id: @game.game_id
      # TODO: more search terms
    , ({data: notes, returnCode}) =>
      if returnCode is 0
        @game.notes =
          new Note o for o in notes
        @updateGrid cb
      else
        @error "Failed to search for notes"

  updateGrid: (cb) ->
    $('#the-note-grid').html ''
    for note in @game.notes
      appendTo $('#the-note-grid'), 'p', text: note.description
    cb()

  installListeners: ->
    $('#the-user-logo, #the-menu-button').click =>
      $('body').toggleClass 'is-mode-menu'
    $('#the-add-button').click =>
      $('body').toggleClass 'is-mode-add'
    $('#the-icon-bar-x').click =>
      $('body').removeClass 'is-mode-add'
      $('body').removeClass 'is-mode-note'
    if @aris.auth?
      $('body').addClass 'is-logged-in'
    $('#the-logout-button').click => @logout()
    $('#the-tag-button').click =>
      $('body').toggleClass 'is-mode-tags'

  logout: ->
    @aris.logout()
    $('body').removeClass 'is-logged-in'

  error: (s) ->
    # TODO
    console.log "ERROR: #{s}"

  warn: (s) ->
    # TODO
    console.log "Warning: #{s}"

app = new App
window.app = app
