console.log 'CoffeeScript loaded.'

$.cookie.json = true

class App
  constructor: ->
    $(document).ready =>

      $('#form-login').submit =>
        @login $('#text-username').val(), $('#text-password').val(), =>
          if @auth?
            @selectPage '#page-list'
        false
      $('#button-logout').click =>
        @logout()
        @selectPage '#page-login'

      @loadLogin()
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

  loadLogin: ->
    @auth = $.cookie 'auth'

  login: (username, password, cb = (->)) ->
    @callAris 'users.logIn',
      user_name: username
      password: password
      permission: 'read_write'
    , ({data: user, returnCode}) =>
      if returnCode is 0
        @auth =
          user_id:    parseInt user.user_id
          permission: 'read_write'
          key:        user.read_write_key
        $.cookie 'auth', @auth
      cb()

  logout: ->
    @auth = null
    $.removeCookie 'auth'

  selectPage: (page) ->
    $('.page').hide()
    $(page).show()

  getGames: (cb = (->)) ->
    @callAris 'games.getGamesForUser', {}, ({data: games}) =>
      @games = for game in games
        game_id: parseInt game.game_id
        name: game.name
        description: game.description
        icon_media_id: parseInt game.icon_media_id
        map_latitude: parseFloat game.map_latitude
        map_longitude: parseFloat game.map_longitude
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
