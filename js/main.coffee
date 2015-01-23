class App
  constructor: ->
    $(document).ready =>

      $.cookie.json = true

      $('#button-login').click =>
        @login $('#text-username').val(), $('#text-password').val(), =>
          if @auth?
            @selectPage '#page-list'
        false
      $('#button-new-acct').click =>
        @selectPage '#page-new-acct'
      $('#button-logout').click =>
        @logout()
        @selectPage '#page-login'
      $('#button-create-acct').click =>
        if '@' not in $('#text-new-email').val()
          $('#alert-new-acct').text "Your email address is not valid."
          $('#alert-new-acct').show()
        else if $('#text-new-username').val().length < 1
          $('#alert-new-acct').text "Your username must be at least 1 character."
          $('#alert-new-acct').show()
        else if $('#text-new-password').val() isnt $('#text-new-password-2').val()
          $('#alert-new-acct').text "Your passwords do not match."
          $('#alert-new-acct').show()
        else if $('#text-new-password').val().length < 6
          $('#alert-new-acct').text "Your password must be at least 6 characters."
          $('#alert-new-acct').show()
        else
          $('#alert-new-acct').hide()
          @callAris 'users.createUser',
            user_name: $('#text-new-username').val()
            password: $('#text-new-password').val()
            email: $('#text-new-email').val()
          , (res) =>
            @parseLogInResult res
            if @auth?
              @selectPage '#page-list'
        false
      $('#button-cancel-new-acct').click =>
        @selectPage '#page-login'

      @loadLogin()
      @updateNav()
      @startingPage()

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
      cb()

  logout: ->
    @auth = null
    $.removeCookie 'auth'
    @updateNav()

  selectPage: (page) ->
    $('#alert-new-acct').hide()
    $('.page').hide()
    $(page).show()

  getGames: (cb = (->)) ->
    @callAris 'games.getGamesForUser', {}, ({data: games}) =>
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
        , ({data: media}) =>
          game.icon_media = media
          @getGameIcons cb
        return
    cb()

app = new App
window.app = app
