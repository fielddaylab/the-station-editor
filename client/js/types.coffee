class window.Game
  constructor: (json) ->
    @game_id   = parseInt json.game_id
    @name      = json.name
    @latitude  = parseFloat json.map_latitude
    @longitude = parseFloat json.map_longitude
    @zoom      = parseInt json.map_zoom_level

class window.User
  constructor: (json) ->
    @user_id      = parseInt json.user_id
    @display_name = json.display_name or json.user_name

class window.Tag
  constructor: (json) ->
    @icon_url = json.media?.data?.url
    @tag      = json.tag
    @tag_id   = parseInt json.tag_id

class window.Comment
  constructor: (json) ->
    @description = json.description
    @comment_id  = parseInt json.note_comment_id
    @user        = new User json.user
    @created     = new Date(json.created.replace(' ', 'T') + 'Z')

class window.Note
  constructor: (json) ->
    @note_id      = parseInt json.note_id
    @user         = new User json.user
    @description  = json.description
    @photo_url    =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.url
    @thumb_url =
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
