class App
  constructor: ->
    $(document).ready =>

      $.cookie.json = true

      $('#button-login').click =>
        $('#spinner-login').show()
        @login $('#text-username').val(), $('#text-password').val(), =>
          $('#spinner-login').hide()
          if @auth?
            @selectPage '#page-list'
          else
            @showAlert 'Incorrect username or password.'
        false

      $('#button-new-acct').click =>
        @selectPage '#page-new-acct'

      $('#menu-logout').click =>
        @logout()
        @selectPage '#page-login'

      $('#menu-change-password').click =>
        @selectPage '#page-change-password'

      $('#button-create-acct').click =>
        if '@' not in $('#text-new-email').val()
          @showAlert "Your email address is not valid."
        else if $('#text-new-username').val().length < 1
          @showAlert "Your username must be at least 1 character."
        else if $('#text-new-password').val() isnt $('#text-new-password-2').val()
          @showAlert "Your passwords do not match."
        else if $('#text-new-password').val().length < 6
          @showAlert "Your password must be at least 6 characters."
        else
          @callAris 'users.createUser',
            user_name: $('#text-new-username').val()
            password: $('#text-new-password').val()
            email: $('#text-new-email').val()
          , (res) =>
            if res.returnCode isnt 0
              @showAlert "Couldn't create account: #{res.returnCodeDescription}"
            else
              @parseLogInResult res
              $('#the-alert').hide()
              @startingPage()
        false

      $('#button-change-password').click =>
        if $('#text-change-password').val() isnt $('#text-change-password-2').val()
          @showAlert "Your new passwords do not match."
        else if $('#text-change-password').val().length < 6
          @showAlert "Your new password must be at least 6 characters."
        else
          @callAris 'users.changePassword',
            user_name: @auth.username
            old_password: $('#text-old-password').val()
            new_password: $('#text-change-password').val()
          , (res) =>
            if res.returnCode isnt 0
              @showAlert "Couldn't change password: #{res.returnCodeDescription}"
            else
              @parseLogInResult res
              $('#the-alert').hide()
              @startingPage()
        false

      $('#button-cancel-new-acct').click =>
        @selectPage '#page-login'

      @loadLogin()
      @updateNav()
      @updateGameList =>
        @startingPage()

  showAlert: (str) ->
    $('#the-alert').text str
    $('#the-alert').show()

  startingPage: ->
    if @auth?
      @selectPage '#page-list'
    else
      @selectPage '#page-login'

  # Calls a function from the Aris v2 API. For debugging purposes,
  # if no callback is given, the JSON result is logged and saved in @arisResult.
  callAris: (func, json, cb = (x) -> @arisResult = x; console.log x) ->
    if @auth?
      json.auth = @auth
    req = new XMLHttpRequest
    req.onreadystatechange = =>
      if req.readyState is 4
        if req.status is 200
          cb JSON.parse req.responseText
        else
          cb false
    req.open 'POST', "http://dev.arisgames.org/server/json.php/v2.#{func}", true
    req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
    req.send JSON.stringify json

  updateNav: ->
    if @auth?
      $('#span-username').text @auth.username
      $('#dropdown-logged-in').show()
    else
      $('#dropdown-logged-in').hide()

  loadLogin: ->
    @auth = $.cookie 'auth'

  # Given the JSON result of users.logIn, if it was successful,
  # stores the authentication details and updates the top nav bar.
  parseLogInResult: ({data: user, returnCode}) =>
    if returnCode is 0
      @auth =
        user_id:    parseInt user.user_id
        permission: 'read_write'
        key:        user.read_write_key
        username:   user.user_name
      $.cookie 'auth', @auth
      @updateNav()

  login: (username, password, cb = (->)) ->
    @callAris 'users.logIn',
      user_name: username
      password: password
      permission: 'read_write'
    , (res) =>
      @parseLogInResult res
      @updateGameList cb

  logout: ->
    @auth = null
    $.removeCookie 'auth'
    @updateNav()

  selectPage: (page) ->
    $('#the-alert').hide()
    $('.page').hide()
    $(page).show()

  updateGameList: (cb = (->)) ->
    @games = []
    gameList = $('#list-siftrs')
    gameList.text ''
    updateDom = =>
      for game in @games
        do (game) =>
          media = $ '<div />', class: 'media'
          do =>
            linkEdit = $ '<a />', href: '#'
            do =>
              mediaLeft = $ '<div />', class: 'media-left'
              do =>
                mediaLeft.append $ '<img />', class: 'media-object', src: game.icon_media.url, width: '64px', height: '64px'
              linkEdit.append mediaLeft
              mediaBody = $ '<div />', class: 'media-body'
              do =>
                mediaBody.append $ '<h4 />', class: 'media-heading', text: game.name
                mediaBody.append game.description
              linkEdit.append mediaBody
            linkEdit.click => @startEdit game
            media.append linkEdit
          gameList.append media
      cb()
    if @auth?
      @getGames =>
        @getGameIcons =>
          @getGameTags =>
            updateDom()
    else
      updateDom()

  getGames: (cb = (->)) ->
    @callAris 'games.getGamesForUser', {}, (data: games) =>
      @games = for game in games
        game_id:        parseInt game.game_id
        name:           game.name
        description:    game.description
        icon_media_id:  parseInt game.icon_media_id
        map_latitude:   parseFloat game.map_latitude
        map_longitude:  parseFloat game.map_longitude
        map_zoom_level: parseInt game.map_zoom_level
      cb()

  getGameIcons: (cb = (->)) ->
    for game in @games
      unless game.icon_media?
        @callAris 'media.getMedia',
          media_id: game.icon_media_id
        , (data: game.icon_media) =>
          @getGameIcons cb
        return
    cb()

  getGameTags: (cb = (->)) ->
    for game in @games
      unless game.tags?
        @callAris 'tags.getTagsForGame',
          game_id: game.game_id
        , (data: game.tags) =>
          @getGameTags cb
        return
    cb()

  selectedIcon: ->
    $('#div-icon-group').removeClass 'has-success'

  resetIcon: ->
    $('#div-icon-group').addClass 'has-success'
    $('#div-icon-input').fileinput 'clear'
    $('#div-icon-thumb').html ''
    newThumb = $ '<img />', src: @currentGame.icon_media.url
    $('#div-icon-thumb').append newThumb

  updateSiftrName: ->
    box = $('#text-siftr-name')
    if box.val() is @currentGame?.name
      box.parent().addClass 'has-success'
    else
      box.parent().removeClass 'has-success'

  updateSiftrDesc: ->
    box = $('#text-siftr-desc')
    if box.val() is @currentGame?.description
      box.parent().addClass 'has-success'
    else
      box.parent().removeClass 'has-success'

  updateSiftrMap: ->
    pn = @map.getCenter()
    equalish = (x, y) -> Math.abs(x - y) < 0.00001
    if equalish pn.lat(), @currentGame.map_latitude
      if equalish pn.lng(), @currentGame.map_longitude
        if @map.getZoom() is @currentGame.map_zoom_level
          $('#div-map-group').addClass 'has-success'
          return
    $('#div-map-group').removeClass 'has-success'

  startEdit: (game = @currentGame) ->
    @currentGame = game
    $('#text-siftr-name').val game.name
    @updateSiftrName()
    $('#text-siftr-desc').val game.description
    @updateSiftrDesc()
    @resetIcon()
    $('#div-edit-tags').text ''
    for tag in game.tags
      @addTag()
      $('#div-edit-tags input:last').val tag.tag
    @updateTagsMinus()
    if @map?
      @map.setCenter
        lat: game.map_latitude
        lng: game.map_longitude
      @map.setZoom game.map_zoom_level
      @updateSiftrMap()
    else
      @map = new google.maps.Map $('#div-google-map')[0],
        center:
          lat: game.map_latitude
          lng: game.map_longitude
        zoom: game.map_zoom_level
      @updateSiftrMap()
      @map.addListener 'idle', => @updateSiftrMap()
    @selectPage '#page-edit'

  updateTagsMinus: ->
    if $('#div-edit-tags')[0].children.length is 0
      $('#button-minus-tag').addClass    'disabled'
    else
      $('#button-minus-tag').removeClass 'disabled'

  removeTag: ->
    divTags = $('#div-edit-tags')
    if divTags[0].children.length > 0
      divTags[0].removeChild divTags[0].lastChild
    @updateTagsMinus()

  addTag: ->
    divTags = $('#div-edit-tags')
    inputGroup = $ '<div />', class: 'form-group'
    textBox = $ '<input />', type: 'text', class: 'form-control'
    inputGroup.append textBox
    divTags.append inputGroup
    @updateTagsMinus()

# window.testfile = ->
#   $('#file-siftr-icon')[0].files[0].result

app = new App
window.app = app
