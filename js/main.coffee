class App
  constructor: ->
    $(document).ready =>

      $.cookie.json = true

      # Tries to log in, and then either shows an error message
      # or loads the game list page.
      $('#button-login').click =>
        $('#spinner-login').show()
        @login $('#text-username').val(), $('#text-password').val(), =>
          $('#spinner-login').hide()
          if @auth?
            @startingPage()
          else
            @showAlert 'Incorrect username or password.'
        false

      $('#menu-logout').click =>
        @logout()
        @selectPage '#page-login'

      # Validates account creation info, and then either shows an error message,
      # or logs in with the new user and shows their game list.
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

      # Validates password change info, and then either shows an error message,
      # or updates their authentication info and goes back to the game list.
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

      @loadLogin()
      @updateNav()
      @updateGameList =>
        @startingPage()

  # Shows an alert textbox at the top of the page.
  # The alert is cleared upon calling @selectPage.
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

  # Tries to log in the user, update the top nav bar, and download their game list.
  login: (username, password, cb = (->)) ->
    @callAris 'users.logIn',
      user_name: username
      password: password
      permission: 'read_write'
    , (res) =>
      @parseLogInResult res
      @updateGameList cb

  # Removes the user's authentication cookie, and updates the top nav bar.
  logout: ->
    @auth = null
    $.removeCookie 'auth'
    @updateNav()

  # Switch out a new page to show the user.
  # Clears any alerts currently being shown.
  selectPage: (page) ->
    $('#the-alert').hide()
    $('.page').hide()
    $(page).show()

  # Redraws the main page's list of games.
  redrawGameList: ->
    gameList = $('#list-siftrs')
    gameList.text ''
    for game in @games
      do (game) =>
        appendTo gameList, '.media', {}, (media) =>
          appendTo media, '.media-left', {}, (mediaLeft) =>
            appendTo mediaLeft, 'img.media-object',
              src: game.icon_media.url
              width: '64px'
              height: '64px'
          appendTo media, '.media-body', {}, (mediaBody) =>
            appendTo mediaBody, 'h4.media-heading',
              text: game.name
            appendTo mediaBody, 'p',
              text: game.description
            appendTo mediaBody, 'form', {}, (form) =>
              appendTo form, '.form-group', {}, (formGroup) =>
                appendTo formGroup, 'a.btn.btn-primary',
                  href: '#'
                  text: 'Edit Siftr'
                , (button) =>
                  button.click => @startEdit game
                appendTo formGroup, 'a.btn.btn-default.disabled',
                  href: '#'
                  text: 'Edit tags'
                , (button) =>
                  button.click => # TODO

  # Downloads all info for the games this user can edit, and then redraws the
  # game list accordingly.
  updateGameList: (cb = (->)) ->
    @games = []
    if @auth?
      @getGames =>
        @getGameIcons =>
          @getGameTags =>
            @redrawGameList()
            cb()
    else
      @redrawGameList()
      cb()

  # Adds or updates a game in our list given a JSON object from Aris calls
  # such as games.getGame.
  addGameFromJson: (json) ->
    newGame =
      game_id:        parseInt json.game_id
      name:           json.name
      description:    json.description
      icon_media_id:  parseInt json.icon_media_id
      map_latitude:   parseFloat json.map_latitude
      map_longitude:  parseFloat json.map_longitude
      map_zoom_level: parseInt json.map_zoom_level
    for game, i in @games
      if game.game_id is newGame.game_id
        @games[i] = newGame
        return newGame
    @games.push newGame
    newGame

  # Downloads the list of games this user can edit.
  getGames: (cb = (->)) ->
    @callAris 'games.getGamesForUser', {}, (data: games) =>
      @games = []
      @addGameFromJson json for json in games
      cb()

  # Downloads icon media info for each game that doesn't already have it.
  getGameIcons: (cb = (->)) ->
    for game in @games
      unless game.icon_media?
        @callAris 'media.getMedia',
          media_id: game.icon_media_id
        , (data: game.icon_media) =>
          @getGameIcons cb
        return
    cb()

  # Downloads the tag list for each game that doesn't already have it.
  getGameTags: (cb = (->)) ->
    for game in @games
      unless game.tags?
        @callAris 'tags.getTagsForGame',
          game_id: game.game_id
        , (data: game.tags) =>
          @getGameTags cb
        return
    cb()

  # Resets the Siftr icon to its existing state.
  resetIcon: ->
    $('#div-icon-input').fileinput 'clear'
    $('#div-icon-thumb').html ''
    newThumb = $ '<img />', src: @currentGame.icon_media.url
    $('#div-icon-thumb').append newThumb

  # Ensures that the map exists, centers it on the given place, and moves
  # the map object to be a child of the given element.
  createMap: (parent, {lat, lng, zoom}) ->
    if @map?
      @map.setCenter {lat, lng}
      @map.setZoom zoom
    else
      @map = new google.maps.Map $('#the-map')[0],
        center: {lat, lng}
        zoom: zoom
    parent.append @map.getDiv()

  # Starts or resets the edit process for a Siftr, and loads the Edit page.
  startEdit: (game = @currentGame) ->
    @currentGame = game
    $('#text-siftr-name').val game.name
    $('#text-siftr-desc').val game.description
    @resetIcon()
    @createMap $('#div-google-map'),
      lat: game.map_latitude
      lng: game.map_longitude
      zoom: game.map_zoom_level
    @selectPage '#page-edit'

  # If the user chose a new icon, upload it to Aris and get its media ID.
  # If they didn't, just return the existing ID.
  getIconID: (cb = (->)) ->
    if $('#file-siftr-icon')[0].files.length is 0
      cb @currentGame.icon_media_id
    else
      dataURL = $('#file-siftr-icon')[0].files[0].result
      extmap =
        jpg: 'data:image/jpeg;base64,'
        png: 'data:image/png;base64,'
        gif: 'data:image/gif;base64,'
      ext = null
      base64 = null
      for k, v of extmap
        if dataURL.indexOf(v) is 0
          ext    = k
          base64 = dataURL.substring v.length
      unless ext? and base64?
        cb false
        return
      @callAris 'media.createMedia',
        game_id: @currentGame.game_id
        file_name: "upload.#{ext}"
        data: base64
      , (data: media) =>
        cb media.media_id

  # Saves all edits to the name, description, icon, and map center/zoom.
  # Reloads the game list and refreshes the Edit page accordingly.
  editSave: (cb = (->)) ->
    $('#spinner-edit-save').show()
    pn = @map.getCenter()
    @getIconID (media_id) =>
      @callAris 'games.updateGame',
        game_id: @currentGame.game_id
        name: $('#text-siftr-name').val()
        description: $('#text-siftr-desc').val()
        map_latitude: pn.lat()
        map_longitude: pn.lng()
        map_zoom_level: @map.getZoom()
        icon_media_id: media_id
      , (data: json) =>
        newGame = @addGameFromJson json
        @getGameIcons =>
          @getGameTags =>
            @redrawGameList()
            $('#spinner-edit-save').hide()
            @startEdit newGame
            cb newGame

  startNewSiftr: (cb = (->)) ->
    @createMap $('#div-new-google-map'),
      lat: 43.071644
      lng: -89.400658
      zoom: 14
    @updateTagMinus()
    @selectPage '#page-new'

  updateTagMinus: ->
    if $('#div-new-tags')[0].children.length is 0
      $('#button-new-minus-tag').addClass 'disabled'
    else
      $('#button-new-minus-tag').removeClass 'disabled'

  addTag: ->
    appendTo $('#div-new-tags'), '.media', {}, (media) =>
      appendTo media, '.media-left', {}, (mediaLeft) =>
        appendTo mediaLeft, 'img.media-object',
          src: 'http://dev.arisgames.org/server/gamedata/v2/265/aris998d7b671a704a178bd2611b0f167208.jpg'
          width: '64px'
          height: '64px'
      appendTo media, '.media-body', {}, (mediaBody) =>
        appendTo mediaBody, 'input.form-control',
          type: 'text'
          placeholder: 'Tag'
    @updateTagMinus()

  removeTag: ->
    tags = $('#div-new-tags')[0]
    if tags.children.length > 0
      tags.removeChild tags.children[tags.children.length - 1]
      # tags.lastChild returns text nodes which don't show up in .children
    @updateTagMinus()

parseElement = (str) ->
  eatWord = ->
    hash = str.indexOf '#'
    dot  = str.indexOf '.'
    hash = 9999 if hash is -1
    dot  = 9999 if dot  is -1
    word = str[... Math.min(hash, dot)]
    str = str[word.length ..]
    word
  tag = eatWord() or 'div'
  classes = []
  id = null
  until str is ''
    if str[0] is '.'
      str = str[1..]
      classes.push eatWord()
    else if str[0] is '#'
      str = str[1..]
      id = eatWord()
    else
      return false
  {tag, classes, id}

appendTo = (parent, haml = '', attrs = {}, init = (->)) ->
  {tag, classes, id} = parseElement haml
  for c in classes
    attrs.class ?= ''
    attrs.class += " #{c}"
  attrs.id = id if id?
  child = $("<#{tag} />", attrs)
  init child
  parent.append ' '
  parent.append child
  parent.append ' '
  child

app = new App
window.app = app
