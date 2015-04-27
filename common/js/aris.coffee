# Handles Aris v2 authentication and API calls.
class Aris
  constructor: ->
    $.cookie.json = true
    @auth = $.cookie 'aris-auth'

  # Given the JSON result of users.logIn, if it was successful,
  # creates and stores the authentication object.
  parseLogin: ({data: user, returnCode}) ->
    if returnCode is 0 and user.user_id isnt null
      @auth =
        user_id:    parseInt user.user_id
        permission: 'read_write'
        key:        user.read_write_key
        username:   user.user_name
      $.cookie 'aris-auth', @auth, path: '/', expires: 365
    else
      @logout()

  # Logs in with a username and password, or logs in with the existing
  # known `auth` object if you pass `undefined` for the username and password.
  login: (username, password, cb = (->)) ->
    @call 'users.logIn',
      user_name: username
      password: password
      permission: 'read_write'
    , (res) =>
      @parseLogin res
      cb()

  logout: ->
    @auth = null
    $.removeCookie 'aris-auth', path: '/'

  # Calls a function from the Aris v2 API.
  # The callback receives the entire JSON-decoded response.
  call: (func, json, cb) ->
    if @auth?
      json.auth = @auth
    req = new XMLHttpRequest
    req.onreadystatechange = =>
      if req.readyState is 4
        if req.status is 200
          cb JSON.parse req.responseText
        else
          cb false
    req.open 'POST', "#{ARIS_URL}/json.php/v2.#{func}", true
    req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
    req.send JSON.stringify json

window.Aris = Aris
