'use strict'

$ = require 'jquery'

ARIS_URL = 'http://arisgames.org/server/'
SIFTR_URL = window.location.origin + '/'

class Game
  constructor: (json) ->
    @game_id     = parseInt json.game_id
    @name        = json.name
    @description = json.description
    @latitude    = parseFloat json.map_latitude
    @longitude   = parseFloat json.map_longitude
    @zoom        = parseInt json.map_zoom_level

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
    @note_id      = parseInt json.note_id
    @user         = new User json.user
    @description  = json.description
    @photo_url    =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.url
    @thumb_url    =
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
    @comments     = for o in json.comments.data
      comment = new Comment o
      continue unless comment.description.match(/\S/)
      comment
    @published    = json.published

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

  # Perform an ARIS call, but then wrap a successful result with a class.
  callWrapped: (func, json, cb, wrap) ->
    @call func, json, (result) =>
      if result.returnCode is 0 and result.data?
        result.data = wrap result.data
      cb result

  getGame: (json, cb) ->
    @callWrapped 'games.getGame', json, cb, (data) -> new Game data

  getTagsForGame: (json, cb) ->
    @callWrapped 'tags.getTagsForGame', json, cb, (data) -> new Tag o for o in data

  getUsersForGame: (json, cb) ->
    @callWrapped 'users.getUsersForGame', json, cb, (data) -> new User o for o in data

  getGamesForUser: (json, cb) ->
    @callWrapped 'games.getGamesForUser', json, cb, (data) -> new Game o for o in data

for k, v of {Game, User, Tag, Comment, Note, Aris, ARIS_URL, SIFTR_URL}
  exports[k] = v
