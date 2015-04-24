class App
  constructor: ->
    $(document).ready =>

      @aris = new Aris

      @isLoading = false
      @selectPage '#page-loading'
      @isLoading = true

      # Tries to log in, and then either shows an error message
      # or loads the game list page.
      $('#button-login').click =>
        $('#spinner-login').show()
        @login $('#text-username').val(), $('#text-password').val(), =>
          $('#spinner-login').hide()
          if @aris.auth?
            @startingPage()
          else
            @showAlert 'Incorrect username or password.'
        false

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
          @aris.call 'users.createUser',
            user_name: $('#text-new-username').val()
            password: $('#text-new-password').val()
            email: $('#text-new-email').val()
          , (res) =>
            if res.returnCode isnt 0
              @showAlert "Couldn't create account: #{res.returnCodeDescription}"
            else
              @parseLogin res
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
          @aris.call 'users.changePassword',
            user_name: @aris.auth.username
            old_password: $('#text-old-password').val()
            new_password: $('#text-change-password').val()
          , (res) =>
            if res.returnCode isnt 0
              @showAlert "Couldn't change password: #{res.returnCodeDescription}"
            else
              @parseLogin res
              @startingPage()
        false

      $('#text-siftr-url').change => @previewURL()
      $('#text-siftr-url').keyup => @previewURL()

      $(window).on 'hashchange', =>
        @goToHash()

      @updateNav()
      @login undefined, undefined, =>
        @isLoading = false
        @goToHash()

  # Shows an alert textbox at the top of the page.
  # The alert is cleared upon calling @selectPage.
  showAlert: (str, good = false) ->
    $('#the-alert').text str
    if good
      $('#the-alert').removeClass 'alert-danger'
      $('#the-alert').addClass 'alert-success'
    else
      $('#the-alert').removeClass 'alert-success'
      $('#the-alert').addClass 'alert-danger'
    $('#the-alert').show()

  startingPage: ->
    if @aris.auth?
      @selectPage '#page-list'
    else
      @selectPage '#page-login'

  updateNav: ->
    if @aris.auth?
      $('#span-username').text @aris.auth.username
      $('#dropdown-logged-in').show()
      $('#nav-left-logged-in').show()
    else
      $('#dropdown-logged-in').hide()
      $('#nav-left-logged-in').hide()

  # Given the JSON result of users.logIn, if it was successful,
  # stores the authentication details and updates the top nav bar.
  parseLogin: (obj) ->
    @aris.parseLogin obj
    @updateNav()

  # Tries to log in the user, update the top nav bar, and download their game list.
  login: (username, password, cb = (->)) ->
    @aris.login username, password, =>
      @updateNav()
      @updateGameList cb

  # Removes the user's authentication cookie, and updates the top nav bar.
  logout: ->
    @aris.logout()
    @updateNav()

  goToHash: ->
    h = document.location.hash
    switch h
      when '#password'
        if @aris.auth?
          @selectPage '#page-change-password'
        else
          @startingPage()
      when '#logout'
        @logout()
        document.location.hash = ''
      when '#join'
        if @aris.auth?
          @startingPage()
        else
          @selectPage '#page-new-acct'
      else
        if @aris.auth?
          if (res = h.match /^#edit(\d+)$/)?
            game_id = parseInt(res[1])
            games =
              g for g in @games when g.game_id is game_id
            if games.length isnt 0
              @startEdit games[0]
            else
              @startingPage()
          else if (res = h.match /^#tags(\d+)$/)?
            game_id = parseInt(res[1])
            games =
              g for g in @games when g.game_id is game_id
            if games.length isnt 0
              @startEditTags games[0]
            else
              @startingPage()
          else if (res = h.match /^#editors(\d+)$/)?
            game_id = parseInt(res[1])
            games =
              g for g in @games when g.game_id is game_id
            if games.length isnt 0
              @startEditors games[0]
            else
              @startingPage()
          else
            @startingPage()
        else
          @startingPage()

  # Switch out a new page to show the user.
  # Clears any alerts currently being shown.
  selectPage: (page) ->
    return if @isLoading
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
            appendTo mediaLeft, '.media-object',
              style:
                """
                width: 64px;
                height: 64px;
                background-image: url(#{game.icon_media.url});
                background-size: contain;
                background-repeat: no-repeat;
                background-position: center;
                """
          appendTo media, '.media-body', {}, (mediaBody) =>
            appendTo mediaBody, 'a',
              href: "#{SIFTR_URL}#{game.siftr_url ? game.game_id}"
              target: '_blank'
            , (siftrLink) =>
              appendTo siftrLink, 'h4.media-heading',
                text: game.name
            markdown = new Showdown.converter()
            appendTo mediaBody, 'p',
              html: markdown.makeHtml game.description
            appendTo mediaBody, 'form', {}, (form) =>
              appendTo form, '.form-group', {}, (formGroup) =>
                appendTo formGroup, 'a.btn.btn-primary',
                  href: '#edit' + game.game_id
                  text: 'Edit Siftr'
                appendTo formGroup, 'a.btn.btn-default',
                  href: '#tags' + game.game_id
                  text: 'Edit tags'
                appendTo formGroup, 'a.btn.btn-default',
                  href: '#editors' + game.game_id
                  text: 'Editors'
                appendTo formGroup, 'a.btn.btn-danger',
                  html: '<i class="fa fa-remove"></i> Delete Siftr'
                , (button) =>
                  button.click =>
                    @deleteGame = game
                    $('#modal-delete-siftr .modal-body').text "Are you sure you want to delete \"#{game.name}\"?"
                    $('#modal-delete-siftr').modal(keyboard: true)

  # Downloads all info for the games this user can edit, and then redraws the
  # game list accordingly.
  updateGameList: (cb = (->)) ->
    @games = []
    if @aris.auth?
      @getGames =>
        @getAllGameInfo =>
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
      siftr_url:      json.siftr_url or null
      published:      parseInt(json.published) isnt 0
    for game, i in @games
      if game.game_id is newGame.game_id
        @games[i] = newGame
        return newGame
    @games.push newGame
    newGame

  # Downloads the list of games this user can edit.
  getGames: (cb = (->)) ->
    @aris.call 'games.getGamesForUser', {}, (data: games) =>
      @games = []
      for json in games
        continue if json.is_siftr? and not parseInt json.is_siftr
        @addGameFromJson json
      cb()

  # Gets all the missing info for games in the game list.
  getAllGameInfo: (cb = (->)) ->
    actions =
      [ ((cb) => @getGameIcons cb)
      , ((cb) => @getGameTags => @getGameTagCounts cb)
      , ((cb) => @getGameEditors cb)
      ]
    async.parallel actions, cb

  # Downloads icon media info for each game that doesn't already have it.
  getGameIcons: (cb = (->)) ->
    go = (game) => (cb) =>
      if game.icon_media?
        cb()
      else if parseInt(game.icon_media_id) is 0
        game.icon_media =
          url: 'img/uw_shield.png'
        cb()
      else
        @aris.call 'media.getMedia',
          media_id: game.icon_media_id
        , (data: game.icon_media) =>
          cb()
    async.parallel(go(game) for game in @games, cb)

  # Downloads the tag list for each game that doesn't already have it.
  getGameTags: (cb = (->)) ->
    go = (game) => (cb) =>
      if game.tags?
        cb()
      else
        @aris.call 'tags.getTagsForGame',
          game_id: game.game_id
        , (data: game.tags) =>
          cb()
    async.parallel(go(game) for game in @games, cb)

  getGameTagCounts: (cb = (->)) ->
    allTags = [].concat(tag for tag in (game.tags for game in @games) ...) # flat list of tags
    go = (tag) => (cb) =>
      if tag.count?
        cb()
      else
        @aris.call 'tags.countObjectsWithTag',
          object_type: 'NOTE'
          tag_id: tag.tag_id
        , (data: {count}) =>
          tag.count = parseInt count
          cb()
    async.parallel(go(tag) for tag in allTags, cb)

  getGameEditors: (cb = (->)) ->
    go = (game) => (cb) =>
      if game.editors?
        cb()
      else
        @aris.call 'editors.getEditorsForGame',
          game_id: game.game_id
        , (data: game.editors) =>
          cb()
    async.parallel(go(game) for game in @games, cb)

  # Resets the Siftr icon to its existing state.
  resetIcon: ->
    $('#div-icon-input').fileinput 'clear'
    $('#div-icon-thumb').html ''
    appendTo $('#div-icon-thumb'), 'img', src: @currentGame.icon_media.url

  # Ensures that the map exists, and centers it on the given place.
  createMap: ({lat, lng, zoom}) ->
    if @map?
      @map.setCenter {lat, lng}
      @map.setZoom zoom
    else
      @map = new google.maps.Map $('#the-map')[0],
        center: {lat, lng}
        zoom: zoom

  # Starts or resets the edit process for a Siftr, and loads the Edit page.
  startEdit: (game = @currentGame) ->
    @currentGame = game
    $('#text-siftr-name').val game.name
    $('#text-siftr-desc').val game.description
    $('#text-siftr-url').val game.siftr_url
    $('#checkbox-siftr-published').prop 'checked', game.published
    @resetIcon()
    @createMap
      lat: game.map_latitude
      lng: game.map_longitude
      zoom: game.map_zoom_level
    @previewURL()
    @selectPage '#page-edit'

  # Updates the URL preview with whatever is in the URL field (or the game ID if empty).
  previewURL: ->
    url = SIFTR_URL + ($('#text-siftr-url').val() or @currentGame.game_id)
    $('#code-siftr-url-template').text url

  # Given a file <input> element, gets the base-64 data from it
  # and creates a new media object inside the given game.
  uploadMediaFromInput: (input, game, cb) ->
    reader = new FileReader
    reader.onload = (e) =>
      dataURL = e.target.result
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
      if ext? and base64?
        @aris.call 'media.createMedia',
          game_id: game.game_id
          file_name: "upload.#{ext}"
          data: base64
        , cb
      else
        cb false
    reader.readAsDataURL $(input)[0].files[0]

  # If the user chose a new icon, upload it to Aris and get its media ID.
  # If they didn't, just return the existing ID.
  getIconID: (cb = (->)) ->
    if $('#file-siftr-icon')[0].files.length is 0
      cb @currentGame.icon_media_id
    else
      @uploadMediaFromInput '#file-siftr-icon', @currentGame
      , (data: media) =>
        cb media.media_id

  # Saves all edits to the name, description, icon, and map center/zoom.
  # Reloads the game list and refreshes the Edit page accordingly.
  editSave: (cb = (->)) ->
    $('#spinner-edit-save').show()
    pn = @map.getCenter()
    @getIconID (media_id) =>
      @aris.call 'games.updateGame',
        game_id: @currentGame.game_id
        name: $('#text-siftr-name').val()
        description: $('#text-siftr-desc').val()
        siftr_url: $('#text-siftr-url').val()
        published: if $('#checkbox-siftr-published').prop('checked') then 1 else 0
        map_latitude: pn.lat()
        map_longitude: pn.lng()
        map_zoom_level: @map.getZoom()
        icon_media_id: media_id
      , ({data: json, returnCode, returnCodeDescription}) =>
        if returnCode isnt 0
          @showAlert returnCodeDescription
          $('#spinner-edit-save').hide()
        else
          newGame = @addGameFromJson json
          @getAllGameInfo =>
            @redrawGameList()
            $('#spinner-edit-save').hide()
            window.location.hash = '#'
            cb newGame

  makeNewSiftr: ->
    $('#spinner-new-siftr').show()
    @aris.call 'games.createGame',
      name: 'Your New Siftr'
      description: ''
      map_latitude: 43.071644
      map_longitude: -89.400658
      map_zoom_level: 14
      is_siftr: 1
      published: 0
    , (data: game) =>
      @addGameFromJson game
      @aris.call 'tags.createTag',
        game_id: game.game_id
        tag: 'Your First Tag'
      , (data: tag) =>
        @getAllGameInfo =>
          @redrawGameList()
          $('#spinner-new-siftr').hide()
          @showAlert 'Your Siftr has been created! Click "Edit Siftr" to get started.', true

  # Prevents deleting a tag if it's the only one on the Edit Tags screen.
  # Prevents adding a tag if there are already 8.
  ableEditTags: ->
    if $('#div-edit-tags').children().length is 1
      $('.delete-tag').addClass 'disabled'
    else
      $('.delete-tag').removeClass 'disabled'
    if $('#div-edit-tags').children().length >= 8
      $('#button-add-tag').addClass 'disabled'
    else
      $('#button-add-tag').removeClass 'disabled'

  addTagEditor: (tag) ->
    appendTo $('#div-edit-tags'), '.media', {}, (media) =>
      appendTo media, '.media-left', {}, (mediaLeft) =>
        appendTo mediaLeft, '.fileinput.fileinput-new', 'data-provides': 'fileinput', (fileInput) =>
          thumb = appendTo fileInput, '.fileinput-preview.thumbnail',
            'data-trigger': 'fileinput'
            style: 'width: 64px; height: 64px;'
          , (thumb) => appendTo thumb, 'img', src: tag?.media?.data?.url
          appendTo fileInput, 'input.new-tag-icon',
            type: 'file'
            name: '...'
            style: 'display: none;'
          , (iconInput) =>
            iconInput.change =>
              thumb.addClass 'icon-uploading'
              @uploadMediaFromInput iconInput, @currentGame, (data: media) =>
                @aris.call 'tags.updateTag',
                  tag_id: tag.tag_id
                  media_id: media.media_id
                , (data: newTag) =>
                  thumb.removeClass 'icon-uploading'
                  tag.media = newTag.media
                  tag.media_id = newTag.media_id
      appendTo media, '.media-body', {}, (mediaBody) =>
        appendTo mediaBody, 'form', {}, (form) =>
          appendTo form, '.form-group.has-success', {}, (formGroup) =>
            appendTo formGroup, '.input-group', {}, (inputGroup) =>
              lastEdited = Date.now()
              lastUploaded = Date.now()
              input = appendTo inputGroup, 'input.form-control',
                type: 'text'
                placeholder: 'Tag'
                val: tag.tag
              appendTo inputGroup, 'span.input-group-addon',
                text: if tag.count is 1 then "1 note" else "#{tag.count} notes"
              saved = edited = uploading = null
              appendTo inputGroup, 'span.input-group-addon', {}, (addon) =>
                saved     = appendTo addon, 'i.fa.fa-check'
                edited    = appendTo addon, 'i.fa.fa-edit', style: 'display: none;'
                uploading = appendTo addon, 'i.fa.fa-spinner.fa-pulse', style: 'display: none;'
              onEdit = =>
                lastEdited = thisEdited = Date.now()
                saved.hide()
                edited.show()
                uploading.hide()
                formGroup.removeClass 'has-success'
                setTimeout =>
                  if lastEdited is thisEdited
                    lastUploaded = thisUploaded = Date.now()
                    saved.hide()
                    edited.hide()
                    uploading.show()
                    newValue = input.val()
                    @aris.call 'tags.updateTag',
                      tag_id: tag.tag_id
                      tag: newValue
                    , =>
                      tag.tag = newValue
                      if lastUploaded is thisUploaded
                        if lastEdited < thisUploaded
                          saved.show()
                          edited.hide()
                          uploading.hide()
                          formGroup.addClass 'has-success'
                        else
                          # there was an edit while we were uploading,
                          # so it will finish and then change icons
                      else
                        # there was an upload while we were uploading,
                        # so it will finish and then change icons
                , 500
              input.keydown onEdit
          appendTo form, '.form-group', {}, (formGroup) =>
            appendTo formGroup, 'a.btn.btn-danger.delete-tag',
              html: '<i class="fa fa-remove"></i> Delete tag'
            , (btn) =>
              btn.click =>
                @tagToDelete = tag
                @tagEditorToDelete = media
                message = "Are you sure you want to delete the tag \"#{tag.tag}\"?"
                switch tag.count
                  when 0
                    null
                  when 1
                    message += " 1 note with this tag will be deleted."
                  else
                    message += " #{tag.count} notes with this tag will be deleted."
                $('#modal-delete-tag .modal-body').text message
                $('#modal-delete-tag').modal(keyboard: true)
    @ableEditTags()

  startEditTags: (game) ->
    @currentGame = game
    $('#div-edit-tags').html ''
    @addTagEditor tag for tag in game.tags
    @selectPage '#page-edit-tags'

  startEditors: (game) ->
    @currentGame = game
    $('#div-editor-list').html ''
    @addEditorListing user for user in game.editors
    @selectPage '#page-editors'

  addEditorListing: (user) ->
    appendTo $('#div-editor-list'), 'li', {}, (li) =>
      li.text user.user_name

  editAddTag: ->
    $('#spinner-add-tag').show()
    @aris.call 'tags.createTag',
      game_id: @currentGame.game_id
    , (res) =>
      if res.returnCode is 0
        tag = res.data
        tag.count = 0
        @currentGame.tags.push tag
        @addTagEditor tag
      else
        @showAlert res.returnCodeDescription
      $('#spinner-add-tag').hide()

  deleteTag: ->
    $('#spinner-delete-tag').show()
    @aris.call 'tags.deleteTag',
      tag_id: @tagToDelete.tag_id
    , (res) =>
      if res.returnCode is 0
        @tagEditorToDelete.remove()
        @ableEditTags()
        @currentGame.tags =
          t for t in @currentGame.tags when t isnt @tagToDelete
      else
        @showAlert res.returnCodeDescription
      $('#spinner-delete-tag').hide()
      $('#modal-delete-tag').modal 'hide'

  deleteSiftr: ->
    $('#spinner-delete-siftr').show()
    @aris.call 'games.deleteGame',
      game_id: @deleteGame.game_id
    , (res) =>
      if res.returnCode is 0
        @games =
          g for g in @games when g isnt @deleteGame
        @redrawGameList()
        $('#the-alert').hide()
      else
        @showAlert res.returnCodeDescription
      $('#modal-delete-siftr').modal 'hide'
      $('#spinner-delete-siftr').hide()

app = new App
window.app = app
