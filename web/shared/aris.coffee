'use strict'

$ = require 'jquery'

ARIS_URL = 'https://arisgames.org/server/'
SIFTR_URL = window.location.origin + '/'

class Game
  constructor: (json) ->
    if json?
      @game_id       = parseInt json.game_id
      @name          = json.name
      @description   = json.description
      @latitude      = parseFloat json.map_latitude
      @longitude     = parseFloat json.map_longitude
      @zoom          = parseInt json.map_zoom_level
      @siftr_url     = json.siftr_url or null
      @is_siftr      = if parseInt json.is_siftr  then true else false
      @published     = if parseInt json.published then true else false
      @moderated     = if parseInt json.moderated then true else false
      @colors_id     = parseInt(json.colors_id) or null
      @icon_media_id = parseInt json.icon_media_id
      @created       = new Date(json.created.replace(' ', 'T') + 'Z')
      @prompt        = json.prompt
    else
      @game_id       = null
      @name          = null
      @description   = null
      @latitude      = null
      @longitude     = null
      @zoom          = null
      @siftr_url     = null
      @is_siftr      = null
      @published     = null
      @moderated     = null
      @colors_id     = null
      @icon_media_id = null
      @created       = null
      @prompt        = null

  createJSON: ->
    game_id:        @game_id or undefined
    name:           @name or ''
    description:    @description or ''
    map_latitude:   @latitude or 0
    map_longitude:  @longitude or 0
    map_zoom_level: @zoom or 0
    siftr_url:      @siftr_url
    is_siftr:       @is_siftr
    published:      @published
    moderated:      @moderated
    colors_id:      @colors_id
    icon_media_id:  @icon_media_id
    prompt:         @prompt
    fields:         @fields

deserializeGame = (json) ->
  g = Object.assign(new Game, json)
  g.created = new Date(g.created)
  g

class Colors
  constructor: (json) ->
    if json?
      @colors_id = parseInt json.colors_id
      @name      = json.name
      @tag_1     = json.tag_1
      @tag_2     = json.tag_2
      @tag_3     = json.tag_3
      @tag_4     = json.tag_4
      @tag_5     = json.tag_5
      @tag_6     = json.tag_6
      @tag_7     = json.tag_7
      @tag_8     = json.tag_8

class User
  constructor: (json) ->
    if json?
      @user_id      = parseInt json.user_id
      @display_name = json.display_name or json.user_name
      @media_id     = parseInt json.media_id

arisHTTPS = (x) ->
  if typeof x is 'string'
    x.replace('http://arisgames.org', 'https://arisgames.org')
  else
    x

class Tag
  constructor: (json) ->
    if json?
      @icon_url = arisHTTPS(json.media?.data?.url)
      @tag      = json.tag
      @tag_id   = parseInt json.tag_id
      @game_id  = parseInt json.game_id
    else
      @icon_url = null
      @tag      = null
      @tag_id   = null
      @game_id  = null

  createJSON: ->
    tag_id: @tag_id or undefined
    game_id: @game_id
    tag: @tag

class Comment
  constructor: (json) ->
    if json?
      @description = json.description
      @comment_id  = parseInt json.note_comment_id
      @user        = new User json.user
      @created     = new Date(json.created.replace(' ', 'T') + 'Z')
      @note_id     = parseInt json.note_id

class Note
  constructor: (json = null) ->
    if json?
      @note_id      = parseInt json.note_id
      @game_id      = parseInt json.game_id
      if json.user?
        @user       = new User json.user
      else
        @user       = new User
          user_id:      json.user_id
          display_name: json.display_name
      @description  = json.description
      @media_id     = parseInt json.media?.data?.media_id
      @photo_url    =
        if 0 in [parseInt(json.media?.data?.media_id), parseInt(json.media_id)]
          null
        else
          arisHTTPS(json.media?.url ? json.media.data.url)
      @thumb_url    =
        if 0 in [parseInt(json.media?.data?.media_id), parseInt(json.media_id)]
          null
        else
          arisHTTPS(json.media?.big_thumb_url ? json.media.data.big_thumb_url)
      @latitude     = parseFloat json.latitude
      @longitude    = parseFloat json.longitude
      @tag_id       = parseInt json.tag_id
      @created      = new Date(json.created.replace(' ', 'T') + 'Z')
      @player_liked = json.player_liked? and !!(parseInt json.player_liked)
      @note_likes   = parseInt json.note_likes
      @comments     = for o in (json.comments?.data ? [])
        comment = new Comment o
        continue unless comment.description?.match(/\S/)
        comment
      @published    = json.published

deserializeNote = (json) ->
  n = Object.assign(new Note, json)
  n.user = Object.assign(new User, n.user)
  n.created = new Date(n.created)
  n.comments =
    Object.assign(new Comment, o) for o in n.comments
  n

class Field
  constructor: (json = null) ->
    if json?
      @field_id   = parseInt json.field_id
      @game_id    = parseInt json.game_id
      @field_type = json.field_type
      @label      = json.label
      @required   = !!(parseInt json.required)

class FieldOption
  constructor: (json = null) ->
    if json?
      @field_option_id = parseInt json.field_option_id
      @field_id        = parseInt json.field_id
      @game_id         = parseInt json.game_id
      @option          = json.option

class FieldData
  constructor: (json = null) ->
    if json?
      @field_data_id   = parseInt json.field_data_id
      @note_id         = parseInt json.note_id
      @field_id        = parseInt json.field_id
      @field_data      = json.field_data
      @media_id        = parseInt json.media_id
      @media           = json.media
      @field_option_id = parseInt json.field_option_id

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
        user_id:      parseInt user.user_id
        permission:   'read_write'
        key:          user.read_write_key
        username:     user.user_name
        display_name: user.display_name
        media_id:     user.media_id
        email:        user.email
      try
        window.localStorage['aris-auth'] = JSON.stringify @auth
      catch err
        # Private mode in iOS Safari disables local storage.
        # just don't bother remembering the auth.
        null
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
    retry = (n) =>
      $.ajax
        contentType: 'application/json'
        data: JSON.stringify json
        dataType: 'json'
        success: cb
        error: (jqxhr, status, err) =>
          if n is 0
            cb [status, err]
          else
            retry(n - 1)
        processData: false
        type: 'POST'
        url: "#{ARIS_URL}/json.php/v2.#{func}"
    retry 2

  # Perform an ARIS call, but then wrap a successful result with a class.
  callWrapped: (func, json, cb, wrap) ->
    @call func, json, (result) =>
      if result.returnCode is 0 and result.data?
        result.data = wrap result.data
      cb result

  getGame: (json, cb) ->
    @callWrapped 'games.getGame', json, cb, (data) -> new Game data

  searchSiftrs: (json, cb) ->
    @callWrapped 'games.searchSiftrs', json, cb, (data) -> new Game o for o in data

  siftrSearch: (json, cb) ->
    @callWrapped 'notes.siftrSearch', json, cb, (data) ->
      notes:
        new Note o for o in data.notes
      map_notes:
        new Note o for o in data.map_notes
      map_clusters:
        data.map_clusters

  getTagsForGame: (json, cb) ->
    @callWrapped 'tags.getTagsForGame', json, cb, (data) -> new Tag o for o in data

  getUsersForGame: (json, cb) ->
    @callWrapped 'users.getUsersForGame', json, cb, (data) -> new User o for o in data

  getFieldsForGame: (json, cb) ->
    @callWrapped 'fields.getFieldsForGame', json, cb, (data) ->
      fields =
        new Field o for o in data.fields
      options =
        new FieldOption o for o in data.options
      for field in fields
        field.options =
          opt for opt in options when field.field_id is opt.field_id
      fields

  getGamesForUser: (json, cb) ->
    @callWrapped 'games.getGamesForUser', json, cb, (data) -> new Game o for o in data

  searchNotes: (json, cb) ->
    @callWrapped 'notes.searchNotes', json, cb, (data) -> new Note o for o in data

  createGame: (game, cb) ->
    @callWrapped 'games.createGame', game.createJSON(), cb, (data) -> new Game data

  updateGame: (game, cb) ->
    @callWrapped 'games.updateGame', game.createJSON(), cb, (data) -> new Game data

  getColors: (json, cb) ->
    @callWrapped 'colors.getColors', json, cb, (data) -> new Colors data

  createTag: (tag, cb) ->
    @callWrapped 'tags.createTag', tag.createJSON(), cb, (data) -> new Tag data

  updateTag: (json, cb) ->
    @callWrapped 'tags.updateTag', json, cb, (data) -> new Tag data

  createNoteComment: (json, cb) ->
    @callWrapped 'note_comments.createNoteComment', json, cb, (data) -> new Comment data

  updateNoteComment: (json, cb) ->
    @callWrapped 'note_comments.updateNoteComment', json, cb, (data) -> new Comment data

  getNoteCommentsForNote: (json, cb) ->
    @callWrapped 'note_comments.getNoteCommentsForNote', json, cb, (data) -> new Comment o for o in data

  getFieldDataForNote: (json, cb) ->
    @callWrapped 'fields.getFieldDataForNote', json, cb, (data) -> new FieldData o for o in data

  getFollowedGamesForUser: (json, cb) ->
    @callWrapped 'games.getFollowedGamesForUser', json, cb, (data) -> new Game o for o in data

  getStaffPicks: (json, cb) ->
    @callWrapped 'games.getStaffPicks', json, cb, (data) -> new Game o for o in data

  getNearbyGamesForPlayer: (json, cb) ->
    @callWrapped 'client.getNearbyGamesForPlayer', json, cb, (data) -> new Game o for o in data

for k, v of {Game, User, Tag, Comment, Note, Field, FieldOption, FieldData, Aris, ARIS_URL, SIFTR_URL, arisHTTPS}
  exports[k] = v
