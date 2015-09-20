# Handles Aris v2 authentication and API calls.
class Aris
  constructor: ->
    authJSON = window.localStorage['aris-auth']
    @auth = if authJSON? then JSON.parse authJSON else null

  # Given the JSON result of users.logIn, if it was successful,
  # creates and stores the authentication object.
  parseLogin: ({data: user, returnCode}) ->
    if returnCode is 0 and user.user_id isnt null
      @auth =
        user_id:    parseInt user.user_id
        permission: 'read_write'
        key:        user.read_write_key
        username:   user.user_name
      window.localStorage['aris-auth'] = JSON.stringify @auth
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
    window.localStorage.removeItem 'aris-auth'

  # Calls a function from the Aris v2 API.
  # The callback receives the entire JSON-decoded response.
  call: (func, json, cb) ->
    if @auth?
      json.auth = @auth
    $.ajax
      contentType: 'application/json'
      data: JSON.stringify json
      dataType: 'json'
      success: cb
      error: -> cb false
      processData: false
      type: 'POST'
      url: "#{ARIS_URL}/json.php/v2.#{func}"

window.Aris = Aris
