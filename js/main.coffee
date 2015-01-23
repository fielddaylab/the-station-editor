class App
  constructor: ->
    $(document).ready =>

      $.cookie.json = true

      $('#button-login').click =>
        @login $('#text-username').val(), $('#text-password').val(), =>
          if @auth?
            @selectPage '#page-list'
          else
            $('#alert-login').text "Incorrect username or password."
            $('#alert-login').show()
        false
      $('#button-new-acct').click =>
        @selectPage '#page-new-acct'
      $('#menu-logout').click =>
        @logout()
        @selectPage '#page-login'
      $('#menu-change-password').click =>
        @selectPage '#page-change-password'
      $('#button-create-acct').click =>
        showAlert = (text) =>
          $('#alert-new-acct').text text
          $('#alert-new-acct').show()
        if '@' not in $('#text-new-email').val()
          showAlert "Your email address is not valid."
        else if $('#text-new-username').val().length < 1
          showAlert "Your username must be at least 1 character."
        else if $('#text-new-password').val() isnt $('#text-new-password-2').val()
          showAlert "Your passwords do not match."
        else if $('#text-new-password').val().length < 6
          showAlert "Your password must be at least 6 characters."
        else
          @callAris 'users.createUser',
            user_name: $('#text-new-username').val()
            password: $('#text-new-password').val()
            email: $('#text-new-email').val()
          , (res) =>
            if res.returnCode isnt 0
              showAlert "Couldn't create account: #{res.returnCodeDescription}"
            else
              @parseLogInResult res
              $('.alert').hide()
              @startingPage()
        false
      $('#button-change-password').click =>
        showAlert = (text) =>
          $('#alert-change-password').text text
          $('#alert-change-password').show()
        if $('#text-change-password').val() isnt $('#text-change-password-2').val()
          showAlert "Your new passwords do not match."
        else if $('#text-change-password').val().length < 6
          showAlert "Your new password must be at least 6 characters."
        else
          @callAris 'users.changePassword',
            user_name: @auth.username
            old_password: $('#text-old-password').val()
            new_password: $('#text-change-password').val()
          , (res) =>
            if res.returnCode isnt 0
              showAlert "Couldn't change password: #{res.returnCodeDescription}"
            else
              @parseLogInResult res
              $('.alert').hide()
              @startingPage()
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
    $('.alert').hide()
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
