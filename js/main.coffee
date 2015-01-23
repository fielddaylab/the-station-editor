console.log 'CoffeeScript loaded.'

$.cookie.json = true

# Calls a function on the Aris v2 API. For debugging purposes,
# if no callback is given, the JSON result is printed and saved in arisResult.
callAris = (func, json, cb = (x) -> window.arisResult = x; console.log x) ->
  req = new XMLHttpRequest
  req.onreadystatechange = ->
    if req.readyState is 4
      if req.status is 200
        cb JSON.parse req.responseText
      else
        cb false
  req.open 'POST', "http://dev.arisgames.org/server/json.php/v2.#{func}", true
  req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
  req.send JSON.stringify json

loadLogin = ->
  window.auth = $.cookie 'auth'

login = (username, password, cb = (->)) ->
  callAris 'users.logIn',
    user_name: username
    password: password
    permission: 'read_write'
  , ({data: user, returnCode}) ->
    if returnCode is 0
      window.auth =
        user_id: parseInt user.user_id
        permission: 'read_write'
        key: user.read_write_key
      $.cookie 'auth', window.auth
    cb()

logout = ->
  window.auth = null
  $.removeCookie 'auth'

selectPage = (page) ->
  $('.page').addClass 'page-hidden'
  $(page).removeClass 'page-hidden'

$(document).ready ->

  $('#button-login').click ->
    login $('#text-username').val(), $('#text-password').val(), ->
      if window.auth?
        selectPage '#page-list'
  $('#button-logout').click ->
    logout()
    selectPage '#page-login'

  loadLogin()
  if window.auth?
    selectPage '#page-list'
  else
    selectPage '#page-login'

window.callAris = callAris
