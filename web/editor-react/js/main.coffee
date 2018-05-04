React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v
{make, child, raw, props} = require '../../shared/react-writer.js'

renderMarkdown = (str) ->
  __html: markdown.toHTML(str ? '')

singleObj = (k, v) ->
  obj = {}
  obj[k] = v
  obj

countContributors = (notes) ->
  user_ids = {}
  for note in notes
    user_ids[note.user.user_id] = true
    for comment in note.comments
      user_ids[comment.user.user_id] = true
  Object.keys(user_ids).length

onSuccess = (fn) -> ({returnCode, returnCodeDescription}) ->
  if returnCode is 0
    fn()
  else
    alert "An error occurred: #{returnCodeDescription}"

reactBind = (fn, obj) ->
  fn
  # TODO: when we upgrade to newer React, change this to fn.bind(obj)

App = React.createClass
  displayName: 'App'

  getInitialState: ->
    auth: null
    games: []
    tags: {}
    notes: {}
    forms: {}
    colors: {}
    username: ''
    password: ''
    screen: 'main'
    edit_game: null
    new_game: do =>
      g = new Game
      g.colors_id = 1
      g.latitude = 43.087806
      g.longitude = -89.430121
      g.zoom = 12
      g.is_siftr = true
      g
    new_tag_string: ''
    new_step: null
    new_icon: null
    account_menu: false

  componentDidMount: ->
    @login undefined, undefined
    @applyHash()
    window.addEventListener 'hashchange', => @applyHash()
    @getColors()

  applyHash: ->
    @setState account_menu: false
    hash = window.location.hash[1..]
    if (md = hash.match(/^edit(.*)/))?
      game_id = parseInt md[1]
      matchingGames =
        game for game in @state.games when game.game_id is game_id
      if matchingGames.length is 1
        @setState
          screen: 'edit'
          mobile_map_is_open: false
          edit_game: matchingGames[0]
      else
        @setState screen: 'main'
        # This is temporary if the user is currently being logged in,
        # because the list of games will load and re-call applyHash
    else if (md = hash.match(/^categories(.*)/))?
      game_id = parseInt md[1]
      matchingGames =
        game for game in @state.games when game.game_id is game_id
      if matchingGames.length is 1
        @setState
          screen: 'categories'
          delete_tag: null
          edit_game: matchingGames[0]
      else
        @setState screen: 'main'
        # This is temporary if the user is currently being logged in,
        # because the list of games will load and re-call applyHash
    else if (md = hash.match(/^form(.*)/))?
      game_id = parseInt md[1]
      matchingGames =
        game for game in @state.games when game.game_id is game_id
      if matchingGames.length is 1
        @setState
          screen: 'form'
          edit_game: matchingGames[0]
      else
        @setState screen: 'main'
        # This is temporary if the user is currently being logged in,
        # because the list of games will load and re-call applyHash
    else if (md = hash.match(/^map(.*)/))?
      game_id = parseInt md[1]
      matchingGames =
        game for game in @state.games when game.game_id is game_id
      if matchingGames.length is 1
        @setState
          screen: 'map'
          edit_game: matchingGames[0]
      else
        @setState screen: 'main'
        # This is temporary if the user is currently being logged in,
        # because the list of games will load and re-call applyHash
    else if hash is 'new1'
      @setState
        screen: 'new1'
        new_step: 1
    else if hash is 'new2'
      @setState
        screen: 'new2'
        new_step: 2
    else if hash is 'new3'
      @setState
        screen: 'new3'
        new_step: 3
    else if hash is 'new4'
      @setState
        screen: 'new4'
        new_step: 4
    else if hash is 'new5'
      @setState
        screen: 'new5'
        new_step: 5
    else if hash is 'account'
      @setState
        screen: 'account'
        display_name: @state.auth?.display_name
        email: @state.auth?.email
        old_password: ''
        password: ''
        password2: ''
        new_icon: null
    else if hash is 'forgot'
      @setState screen: 'forgot'
    else if hash is 'signup'
      @setState
        screen: 'signup'
        password: ''
        password2: ''
        email: ''
    else
      @setState screen: 'main'

  login: (username, password) ->
    @props.aris.login username, password, =>
      @updateLogin()
      if (username? or password?) and not @props.aris.auth?
        alert 'Incorrect username or password.'

  logout: ->
    window.location.hash = '#'
    @props.aris.logout()
    @updateLogin()

  updateLogin: ->
    @setState
      auth: @props.aris.auth
      account_menu: false
      password: ''
      password2: ''
    if @props.aris.auth and window.location.pathname.match(/\blogin\b/)
      window.location.href = '../discover/'
    else
      @updateGames()
      @fetchUserPicture()

  getColors: ->
    for i in [1..6] # predefined schemes for now
      do (i) =>
        @props.aris.getColors
          colors_id: i
        , (result) =>
          if result.returnCode is 0 and result.data?
            @setState (previousState, currentProps) =>
              update previousState,
                colors:
                  $merge: singleObj(i, result.data)

  fetchUserPicture: ->
    if @props.aris.auth?
      @props.aris.call 'media.getMedia',
        media_id: @props.aris.auth.media_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState userPicture: result.data
    else
      @setState userPicture: null

  updateGames: ->
    if @props.aris.auth?
      @props.aris.getGamesForUser {}, (result) =>
        if result.returnCode is 0 and result.data?
          games =
            game for game in result.data when game.is_siftr
          @setState
            games: games
            tags: {}
            forms: {}
            notes: {}
          @applyHash()
          @updateTags games
          @updateForms games
          @updateNotes games
        else
          @setState games: []
    else
      @setState games: []

  updateNotes: (games) ->
    games.forEach (game) =>
      @props.aris.searchNotes
        game_id: game.game_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState (previousState, currentProps) =>
            update previousState,
              notes:
                $merge: singleObj(game.game_id, result.data)

  updateForms: (games, cb = (->)) ->
    games.forEach (game) =>
      @props.aris.getFieldsForGame
        game_id: game.game_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState (previousState, currentProps) =>
            update previousState,
              forms:
                $merge: singleObj(game.game_id, result.data)
          , cb

  updateTags: (games) ->
    games.forEach (game) =>
      @props.aris.getTagsForGame
        game_id: game.game_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState (previousState, currentProps) =>
            update previousState,
              tags:
                $merge: singleObj(game.game_id, result.data)

  # Adds the game to the known games list,
  # or updates an existing game if it shares the game ID.
  updateStateGame: (newGame) ->
    @setState (previousState, currentProps) =>
      update previousState,
        games:
          $apply: (games) =>
            foundOld = false
            updated =
              for game in games
                if game.game_id is newGame.game_id
                  foundOld = true
                  newGame
                else
                  game
            if foundOld
              updated
            else
              updated.concat([newGame])

  handleSave: ->
    @props.aris.updateGame @state.edit_game, (result) =>
      window.location.hash = '#'
      if result.returnCode is 0 and result.data?
        @updateStateGame result.data

  createNewIcon: (game, cb) ->
    dataURL = @state.new_icon
    unless dataURL?
      cb null
      return
    extmap =
      jpg: 'data:image/jpeg;base64,'
      png: 'data:image/png;base64,'
      gif: 'data:image/gif;base64,'
    ext = null
    base64 = null
    for k, v of extmap
      if dataURL[0 .. v.length - 1] is v
        ext    = k
        base64 = dataURL[v.length ..]
    if ext? and base64?
      @props.aris.call 'media.createMedia',
        game_id: game?.game_id
        file_name: "upload.#{ext}"
        data: base64
      , cb
    else
      cb null

  createGame: ->
    @props.aris.createGame @state.new_game, (result) =>
      if result.returnCode is 0 and result.data?
        window.location.hash = '#'
        newGame = result.data
        tags = @state.new_tag_string.split(',')
        tagsRemaining = tags.length
        @createNewIcon newGame, (result) =>
          if result?
            @props.aris.call 'games.updateGame',
              game_id: newGame.game_id
              icon_media_id: result.data.media_id
            , ({data: game}) =>
              @updateStateGame(new Game(game))
        for tag, i in tags
          tag = tag.replace(/^\s+/, '')
          continue if tag is ''
          tagObject = new Tag
          tagObject.tag = tag
          tagObject.game_id = newGame.game_id
          @props.aris.createTag tagObject, (result) =>
            if result.returnCode is 0 and result.data?
              tagsRemaining--
              if tagsRemaining is 0
                @updateTags([newGame])
        @updateStateGame newGame
        @updateForms([newGame])
        @setState (previousState, currentProps) =>
          update previousState,
            notes:
              $merge: singleObj(newGame.game_id, [])
            new_game:
              $set: do =>
                g = new Game
                g.colors_id = 1
                g.latitude = 43.087806
                g.longitude = -89.430121
                g.zoom = 12
                g.is_siftr = true
                g
            new_tag_string:
              $set: ''
            new_step:
              $set: null
            new_icon:
              $set: null

  sendPasswordReset: ->
    @props.aris.call 'users.requestForgotPasswordEmail',
      user_name: @state.username
      email:     @state.email
    , ({returnCode}) =>
      if returnCode is 0
        alert 'An email has been sent to that account (if it exists) to reset your password.'
        window.location.replace '#'

  signup: ->
    unless @state.email
      alert 'Please enter your email address.'
    else unless '@' in @state.email
      alert 'Your email address is not valid.'
    else unless @state.username
      alert 'Please select a username.'
    else unless @state.password or @state.password2
      alert 'Please enter a password.'
    else unless @state.password is @state.password2
      alert 'Your passwords do not match.'
    else
      @props.aris.call 'users.createUser',
        user_name: @state.username
        password: @state.password
        email: @state.email
      , ({returnCode, returnCodeDescription}) =>
        if returnCode isnt 0
          alert "Couldn't create account: #{returnCodeDescription}"
        else
          window.location.replace '#'
          @login @state.username, @state.password

  selectUserPicture: ->
    input = document.createElement 'input'
    input.type = 'file'
    input.onchange = (e) => @loadUserPicture e.target.files[0]
    input.click()

  loadUserPicture: (file) ->
    fr = new FileReader
    fr.onload = =>
      @setState new_icon: fr.result
    fr.readAsDataURL file

  continueAutosave: ->
    if (game = @autosavePending)?
      @autosavePending = null
      @props.aris.updateGame game, onSuccess =>
        @continueAutosave()
    else
      @updateGames()
      @setState autosaving: false

  autosave: (game, autosave = true) ->
    @setState edit_game: game
    if autosave
      @autosavePending = game
      unless @state.autosaving
        @setState autosaving: true
        @continueAutosave()

  render: ->
    navBarActions = =>
      child 'div', =>
        if @state.screen in ['new1', 'new2', 'new3', 'new4', 'new5']
          child 'a.create-cancel', href: '#', =>
            raw 'Cancel'
        else if @state.screen in ['edit', 'map']
          if @state.autosaving
            child 'span.create-spinner', =>
              child 'span', => raw 'saving'
              child 'img.spinny-saver', src: '../assets/icons/spinny-saver.png'
          child 'a.create-cancel', href: '#', =>
            raw 'Done'
        else if @state.screen in ['categories', 'form']
          child 'a.create-cancel', href: '#', =>
            raw 'Done'

    make "div.topDiv.accountMenu#{if @state.account_menu then 'Open' else 'Closed'}", =>
      child 'div.nav-bar.desktop-nav-bar', =>
        child 'div.nav-bar-line', =>
          child 'div', =>
            child 'a', href: '..', =>
              child 'img#the-logo', src: '../assets/logos/siftr-logo-black.png'
            if @state.screen in ['new1', 'new2', 'new3', 'new4', 'new5']
              child 'h1.new-siftr-title', =>
                if @state.new_game.name
                  raw @state.new_game.name
                else
                  raw 'New Siftr'
          child 'div', =>
            child 'a', href: '../editor', =>
              child 'div.nav-button-right', =>
                raw 'My Siftrs'
            if @state.auth?
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    @setState account_menu: not @state.account_menu
                child 'div.nav-button-right', =>
                  raw 'My Account'
            child 'a', href: '../discover', =>
              child 'div.nav-button-right', =>
                raw 'Discover'
        if @state.screen in ['new1', 'new2', 'new3', 'new4', 'new5']
          child 'div.nav-bar-line', =>
            child 'div', =>
              selectTab = (step) =>
                if @state.screen is step
                  '.create-step-tab-selected'
                else
                  ''
              child "a.create-step-tab#{selectTab 'new1'}", href: '#new1', =>
                raw 'Overview'
              child "a.create-step-tab#{selectTab 'new2'}", href: '#new2', =>
                raw 'Design'
              child "a.create-step-tab#{selectTab 'new3'}", href: '#new3', =>
                raw 'Location'
              child "a.create-step-tab#{selectTab 'new4'}", href: '#new4', =>
                raw 'Data collection'
              child "a.create-step-tab#{selectTab 'new5'}", href: '#new5', =>
                raw 'Settings'
            navBarActions()
        else if @state.screen in ['edit', 'map', 'categories', 'form']
          child 'div.nav-bar-line', =>
            child 'div', =>
              selectTab = (step) =>
                if @state.screen is step
                  '.create-step-tab-selected'
                else
                  ''
              child "a.create-step-tab#{selectTab 'edit'}", href: '#edit' + @state.edit_game.game_id, =>
                raw 'Settings'
              child "a.create-step-tab#{selectTab 'categories'}", href: '#categories' + @state.edit_game.game_id, =>
                raw 'Categories'
              child "a.create-step-tab#{selectTab 'map'}", href: '#map' + @state.edit_game.game_id, =>
                raw 'Location'
              child "a.create-step-tab#{selectTab 'form'}", href: '#form' + @state.edit_game.game_id, =>
                raw 'Data collection'
            navBarActions()
      child 'div.nav-bar.mobile-nav-bar', =>
        child 'div.nav-bar-line', =>
          child 'div', =>
            child 'a', href: '#', =>
              props
                onClick: (e) =>
                  e.preventDefault()
                  @setState account_menu: not @state.account_menu
              child 'div#the-mobile-menu-button', =>
                raw '☰'
          navBarActions()
      child 'div#the-content', =>
        if @state.auth?
          switch @state.screen
            when 'account'
              child 'div.loginForm', =>
                child 'h3', =>
                  raw 'Account Details'
                child 'p', =>
                  child 'span.big-account-picture',
                    style:
                      backgroundImage:
                        if @state.new_icon?
                          "url(#{@state.new_icon})"
                        else if @state.userPicture?
                          "url(#{@state.userPicture.url})"
                        else
                          undefined
                    onClick: @selectUserPicture
                    onDragOver: (e) =>
                      e.stopPropagation()
                      e.preventDefault()
                    onDrop: (e) =>
                      e.stopPropagation()
                      e.preventDefault()
                      for file in e.dataTransfer.files
                        @loadUserPicture file
                        break
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      @logout()
                  child 'div.login-button', =>
                    raw 'LOGOUT'
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Display Name'
                    value: @state.display_name ? ''
                    onChange: (e) => @setState display_name: e.target.value
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Email'
                    value: @state.email ? ''
                    onChange: (e) => @setState email: e.target.value
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      useMediaID = (media_id) =>
                        @props.aris.call 'users.updateUser',
                          user_id: @props.aris.auth.user_id
                          display_name: @state.display_name
                          email: @state.email
                          media_id: media_id
                        , ({returnCode, returnCodeDescription}) =>
                          if returnCode is 0
                            @login undefined, undefined
                            window.location.replace '#'
                          else
                            alert "Couldn't save your account details: #{returnCodeDescription}"
                      if @state.new_icon?
                        @createNewIcon null, (result) =>
                          if result?
                            useMediaID result.data.media_id
                          else
                            alert "Your user picture is not of a supported type."
                      else
                        useMediaID null
                  child 'div.login-button', =>
                    raw 'SAVE CHANGES'
                child 'a', href: '#', =>
                  child 'div.login-button', =>
                    raw 'BACK'
                child 'h3', =>
                  raw 'Change Password'
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Old password'
                    value: @state.old_password ? ''
                    onChange: (e) => @setState old_password: e.target.value
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'New password'
                    value: @state.password ? ''
                    onChange: (e) => @setState password: e.target.value
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Repeat new password'
                    value: @state.password2 ? ''
                    onChange: (e) => @setState password2: e.target.value
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      unless @state.old_password
                        alert 'Please enter your current password.'
                      else unless @state.password or @state.password2
                        alert 'Please enter a new password.'
                      else unless @state.password is @state.password2
                        alert 'Your two password do not match.'
                      else
                        username = @props.aris.auth.username
                        password = @state.password
                        @props.aris.call 'users.changePassword',
                          user_name: username
                          old_password: @state.old_password
                          new_password: password
                        , ({returnCode, returnCodeDescription}) =>
                          if returnCode is 0
                            @logout()
                            @login username, password
                          else
                            alert "Couldn't change your password: #{returnCodeDescription}"
                  child 'div.login-button', =>
                    raw 'CHANGE PASSWORD'
            when 'edit'
              child EditSiftr,
                game: @state.edit_game
                colors: @state.colors
                onChange: reactBind(@autosave, @)
                mobileMapIsOpen: @state.mobile_map_is_open
                openMobileMap: =>
                  @setState mobile_map_is_open: true
                  setTimeout =>
                    window.dispatchEvent new Event 'resize'
                  , 250
                closeMobileMap: => @setState mobile_map_is_open: false
            when 'form'
              fields = @state.forms[@state.edit_game.game_id]
              child NewStep4,
                editing: true
                game: @state.edit_game
                fields: fields
                addField: (field_type) =>
                  @props.aris.call 'fields.createField',
                    game_id: @state.edit_game.game_id
                    field_type: field_type
                    required: false
                  , onSuccess => @updateForms([@state.edit_game])
                updateField: (field) =>
                  @props.aris.call 'fields.updateField',
                    field
                  , onSuccess => @updateForms([@state.edit_game])
                deleteField: (field) =>
                  @props.aris.call 'fields.deleteField',
                    game_id: @state.edit_game.game_id
                    field_id: field.field_id
                  , onSuccess => @updateForms([@state.edit_game])
                reorderFields: (indexes, cb) =>
                  n = fields.length
                  for field, i in fields
                    @props.aris.call 'fields.updateField',
                      game_id: field.game_id
                      field_id: field.field_id
                      sort_index: indexes.indexOf(i)
                    , onSuccess =>
                      n -= 1
                      if n is 0
                        @updateForms([@state.edit_game], cb)
                addFieldOption: ({field, option}, cb) =>
                  @props.aris.call 'fields.createFieldOption',
                    game_id: @state.edit_game.game_id
                    field_id: field.field_id
                    option: option
                  , onSuccess => @updateForms([@state.edit_game], cb)
                updateFieldOption: ({field_option, option}, cb) =>
                  @props.aris.call 'fields.updateFieldOption',
                    game_id: @state.edit_game.game_id
                    field_id: field_option.field_id
                    field_option_id: field_option.field_option_id
                    option: option
                  , onSuccess => @updateForms([@state.edit_game], cb)
                deleteFieldOption: ({field_option, new_field_option}, cb) =>
                  @props.aris.call 'fields.deleteFieldOption',
                    game_id: @state.edit_game.game_id
                    field_id: field_option.field_id
                    field_option_id: field_option.field_option_id
                    new_field_option_id: new_field_option?.field_option_id
                  , onSuccess => @updateForms([@state.edit_game], cb)
                reorderFieldOptions: (field, indexes, cb) =>
                  n = field.options.length
                  for option, i in field.options
                    @props.aris.call 'fields.updateFieldOption',
                      game_id: field.game_id
                      field_id: field.field_id
                      field_option_id: option.field_option_id
                      sort_index: indexes.indexOf(i)
                    , onSuccess =>
                      n -= 1
                      if n is 0
                        @updateForms([@state.edit_game], cb)
            when 'map'
              child NewStep3,
                editing: true
                game: @state.edit_game
                onChange: reactBind(@autosave, @)
            when 'categories'
              child 'div.newStepBox', =>
                child 'div.loginForm', =>
                  tags = @state.tags[@state.edit_game.game_id]
                  colors = @state.colors[@state.edit_game.colors_id or 1]
                  child 'h2', =>
                    raw "Categories for "
                    child 'b', =>
                      raw @state.edit_game.name
                  if not tags?
                    child 'p', =>
                      raw 'Loading categories...'
                  else if @state.delete_tag?
                    child 'h4', =>
                      raw "Choose a category to reassign all #{@state.delete_tag.tag} notes to."
                    for tag, i in tags
                      continue if tag is @state.delete_tag
                      do (tag, i) =>
                        child 'div.category-button', =>
                          props
                            style:
                              backgroundColor: colors["tag_#{(i % 8) + 1}"]
                            onClick: =>
                              if confirm "Are you sure you want to delete the category \"#{@state.delete_tag.tag}\" and move all its notes to \"#{tag.tag}\"?"
                                @props.aris.call 'tags.deleteTag',
                                  tag_id: @state.delete_tag.tag_id
                                  new_tag_id: tag.tag_id
                                , =>
                                  @setState delete_tag: null
                                  @updateTags [@state.edit_game]
                          raw tag.tag
                    child 'a.new-category-button', href: '#', =>
                      props
                        onClick: (e) =>
                          e.preventDefault()
                          @setState delete_tag: null
                      child 'div.login-button', =>
                        raw 'CANCEL'
                  else
                    for tag, i in tags
                      do (tag, i) =>
                        child 'div.category-button', =>
                          props
                            style:
                              backgroundColor: colors["tag_#{(i % 8) + 1}"]
                            onClick: =>
                              str = prompt "Enter a new name for this category...", tag.tag
                              if str? and str isnt ''
                                @props.aris.updateTag
                                  game_id: @state.edit_game.game_id
                                  tag_id: tag.tag_id
                                  tag: str
                                , =>
                                  @updateTags [@state.edit_game]
                          raw tag.tag
                          child 'div.delete-category-x', =>
                            props
                              onClick: (e) =>
                                e.stopPropagation()
                                @setState delete_tag: tag
                            raw 'X'
                    child 'a.new-category-button', href: '#', =>
                      props
                        onClick: (e) =>
                          e.preventDefault()
                          str = prompt "Enter a new category..."
                          if str? and str isnt ''
                            tagObject = new Tag
                            tagObject.tag = str
                            tagObject.game_id = @state.edit_game.game_id
                            @props.aris.createTag tagObject, =>
                              @updateTags [@state.edit_game]
                      child 'div.login-button', =>
                        raw 'NEW CATEGORY'
                child 'div.bottom-step-buttons', =>
                  child 'a', href: '#edit' + @state.edit_game.game_id, =>
                    child 'div.newPrevButton', =>
                      raw '< settings'
                  child 'a', href: '#map' + @state.edit_game.game_id, =>
                    child 'div.newNextButton', =>
                      raw 'map >'
            when 'new1'
              f = (game, tag_string) => @setState
                new_game: game
                new_tag_string: tag_string
              child NewStep1,
                game: @state.new_game
                tag_string: @state.new_tag_string
                icon: @state.new_icon
                onChange: (new_game, new_tag_string) => @setState {new_game, new_tag_string}
                onIconChange: (new_icon) => @setState {new_icon}
            when 'new2'
              child NewStep2,
                game: @state.new_game
                tag_string: @state.new_tag_string
                colors: @state.colors
                onChange: (new_game, new_tag_string) => @setState {new_game, new_tag_string}
            when 'new3'
              child NewStep3,
                game: @state.new_game
                onChange: (new_game) => @setState {new_game}
            when 'new4'
              child NewStep4,
                editing: false
                game: @state.new_game
                onChange: (new_game) => @setState {new_game}
            when 'new5'
              child NewStep5,
                game: @state.new_game
                onChange: (new_game) => @setState {new_game}
                onCreate: @createGame
            else
              child 'div', =>
                child 'p.new-siftr-para', =>
                  child 'a.new-siftr-button.login-button', href: '#new1', =>
                    raw 'NEW SIFTR'
                child SiftrList,
                  games: @state.games
                  colors: @state.colors
                  notes: @state.notes
                  tags: @state.tags
                  onDelete: (game) =>
                    @props.aris.call 'games.deleteGame',
                      game_id: game.game_id
                    , ({returnCode, returnCodeDescription}) =>
                      if returnCode is 0
                        @updateGames()
                      else
                        alert "There was an error deleting your Siftr: #{returnCodeDescription}"
          child 'div.accountMenuDesktop', =>
            child 'div', =>
              child 'a.unlink', href: '#account', =>
                child 'p', =>
                  child 'span.account-menu-user-pic', style:
                    backgroundImage: if @state.userPicture? then "url(#{arisHTTPS @state.userPicture.thumb_url})" else undefined
                child 'p', =>
                  raw @state.auth.display_name
                child 'div.nav-menu-button', =>
                  raw 'ACCOUNT SETTINGS'
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    @logout()
                child 'div.nav-menu-button', =>
                  raw 'LOGOUT'
        else
          switch @state.screen
            when 'forgot'
              child 'div.loginForm', =>
                child 'p', =>
                  raw 'Enter your username '
                  child 'b', => raw 'or'
                  raw ' email to reset your password.'
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username ? ''
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @sendPasswordReset()
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Email'
                    value: @state.email ? ''
                    onChange: (e) => @setState email: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @sendPasswordReset()
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      @sendPasswordReset()
                  child 'div.login-button', =>
                    raw 'SEND EMAIL'
                child 'a', href: '#', =>
                  child 'div.login-button', =>
                    raw 'BACK'
            when 'signup'
              child 'div.loginForm', =>
                child 'p', =>
                  raw 'Create a new Siftr account'
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Email'
                    value: @state.email ? ''
                    onChange: (e) => @setState email: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username ? ''
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Password'
                    value: @state.password ? ''
                    onChange: (e) => @setState password: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Repeat password'
                    value: @state.password2 ? ''
                    onChange: (e) => @setState password2: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      @signup()
                  child 'div.login-button', =>
                    raw 'CREATE ACCOUNT'
                child 'a', href: '#', =>
                  child 'div.login-button', =>
                    raw 'BACK'
            else
              child 'div.loginForm', =>
                child 'p', =>
                  raw 'Login with a Siftr or ARIS account'
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username ? ''
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @login @state.username, @state.password
                child 'p', =>
                  child 'input.full-width-input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Password'
                    value: @state.password ? ''
                    onChange: (e) => @setState password: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @login @state.username, @state.password
                child 'a', href: '#', =>
                  props
                    onClick: (e) =>
                      e.preventDefault()
                      @login @state.username, @state.password
                  child 'div.login-button', =>
                    raw 'LOGIN'
                child 'a', href: '#signup', =>
                  child 'div.login-button', =>
                    raw 'CREATE ACCOUNT'
                child 'a', href: '#forgot', =>
                  child 'div.login-button', =>
                    raw 'FORGOT PASSWORD?'
      child 'div.accountMenuMobile', =>
        child 'a', href: '#', =>
          props
            onClick: (e) =>
              e.preventDefault()
              @setState account_menu: false
          child 'div', =>
            child 'img',
              src: '../assets/icons/x-white.png'
        child 'div.accountMenuMobileContents', =>
          if @state.auth?
            child 'a.unlink', href: '#account', =>
              child 'p', =>
                child 'span.account-menu-user-pic', style:
                  backgroundImage: if @state.userPicture? then "url(#{arisHTTPS @state.userPicture.thumb_url})" else undefined
              child 'p', => raw @state.auth.display_name
          else
            child 'p', => raw 'Not logged in'
          child 'p', =>
            child 'a', href: '..', =>
              child 'img', src: '../assets/logos/brand-mobile.png'
          child 'p', => child 'a', href: '../editor', => raw 'My Siftrs'
          child 'p', => child 'a', href: '../discover', => raw 'Discover'
          if @state.auth?
            child 'p', =>
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    @logout()
                raw 'Logout'

SiftrList = React.createClass
  displayName: 'SiftrList'

  render: ->
    make 'div.siftrList', =>
      @props.games.forEach (game) =>
        notes = @props.notes[game.game_id]
        child 'div.siftr-entry', key: "game-#{game.game_id}", =>
          child 'div.siftr-entry-title-buttons', =>
            child 'a.siftr-entry-title', href: "#{SIFTR_URL}#{game.siftr_url or game.game_id}", target: '_blank', =>
              raw game.name
            child 'span', =>
              child 'a', href: "\#edit#{game.game_id}", =>
                child 'span.siftr-command-button', =>
                  raw 'EDIT'
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    if confirm "Are you sure you want to delete \"#{game.name}\"?"
                      @props.onDelete game
                child 'span.siftr-command-button', =>
                  raw 'DELETE'
          child 'div.siftr-color-bar', style:
            backgroundImage:
              if (colors = @props.colors[game.colors_id])?
                percent = 0
                points = []
                for i in [1..5]
                  rgb = colors["tag_#{i}"]
                  points.push "#{rgb} #{percent}%"
                  percent += 20
                  points.push "#{rgb} #{percent}%"
                "linear-gradient(to right, #{points.join(', ')})"
              else
                'linear-gradient(to right, gray, gray)'
          child 'div.siftr-data', =>
            sep = => child 'span.siftr-data-pipe', => raw '|'
            raw "#{notes?.length ? '...'} items"
            sep()
            raw "#{if notes? then countContributors(notes) else '...'} contributors"
            sep()
            raw (if game.published then 'Public' else 'Private')
            sep()
            raw (if game.moderated then 'Moderated' else 'Non-Moderated')

EditSiftr = React.createClass
  displayName: 'EditSiftr'

  render: ->
    make 'div.newStepBox', =>
      child 'div.newStep1', =>
        child 'div.newStep1LeftColumn', =>
          child 'form', =>
            child 'h2', => raw @props.game.name
            child 'label', =>
              child 'h4', => raw 'NAME'
              child 'input.full-width-input',
                type: 'text'
                value: @props.game.name ? ''
                onChange: (e) =>
                  game = update @props.game,
                    name:
                      $set: e.target.value
                  @props.onChange game, false
                onBlur: => @props.onChange @props.game, true
            child 'label', =>
              child 'h4', =>
                raw 'DESCRIPTION '
                child 'a', href: 'https://daringfireball.net/projects/markdown/syntax', target: '_blank', =>
                  child 'i', => raw 'markdown supported'
              child 'textarea.full-width-textarea',
                value: @props.game.description ? ''
                onChange: (e) =>
                  game = update @props.game,
                    description:
                      $set: e.target.value
                  @props.onChange game, false
                onBlur: => @props.onChange @props.game, true
            child 'div',
              dangerouslySetInnerHTML: renderMarkdown @props.game.description
            child 'label', =>
              child 'h4', => raw 'URL'
              child 'p', =>
                child 'input.full-width-input',
                  type: 'text'
                  placeholder: 'URL (optional)'
                  value: @props.game.siftr_url ? ''
                  onChange: (e) =>
                    url = e.target.value.replace(/[^A-Za-z0-9_\-]/g, '')
                    @props.onChange update(@props.game, siftr_url: $set: url), false
                  onBlur: => @props.onChange @props.game, true
            child 'p', =>
              child 'b', => raw @props.game.name
              raw " will be located at "
              child 'code', => raw "#{SIFTR_URL}#{@props.game.siftr_url ? @props.game.game_id}"
            child 'label', =>
              child 'h4', => raw 'PROMPT'
              child 'p', =>
                raw 'Enter a caption prompt for a user uploading a photo.'
              child 'p', =>
                child 'input.full-width-input',
                  type: 'text'
                  placeholder: 'Enter a caption...'
                  value: @props.game.prompt ? ''
                  onChange: (e) => @props.onChange update(@props.game, prompt: $set: e.target.value), false
                  onBlur: => @props.onChange @props.game, true
            child 'h2', => raw 'SETTINGS'
            child 'h4', => raw 'PRIVACY'

            hidden = not @props.game.published
            child "a.form-multi-option.form-multi-option-#{if hidden then 'on' else 'off'}", href: '#', =>
              props
                onClick: (e) =>
                  e.preventDefault()
                  @props.onChange update @props.game, published: $set: hidden
              child 'span.form-multi-option-text', =>
                raw 'Hide from search'
              child 'span.form-multi-option-switch', =>
                child 'span.form-multi-option-ball'

            child 'p', =>
              raw 'Do you want to set a password to restrict access?'
            child 'p', =>
              child 'input.full-width-input',
                type: 'text'
                placeholder: 'Password (optional)'
                value: @props.game.password ? ''
                onChange: (e) => @props.onChange update(@props.game, password: $set: e.target.value), false
                onBlur: => @props.onChange @props.game, true

            moderated = @props.game.moderated
            child "a.form-multi-option.form-multi-option-#{if moderated then 'on' else 'off'}", href: '#', =>
              props
                onClick: (e) =>
                  e.preventDefault()
                  @props.onChange update @props.game, moderated: $set: not moderated
              child 'span.form-multi-option-text', =>
                raw 'Require moderation?'
              child 'span.form-multi-option-switch', =>
                child 'span.form-multi-option-ball'

            child 'h2', => raw 'APPEARANCE'
            child 'p', =>
              raw 'What color palette should '
              child 'b', => raw @props.game.name
              raw ' use?'
            colorsRow = (colors_ids) =>
              child 'div.color-table', =>
                for i in colors_ids
                  colors = @props.colors[i]
                  rgbs =
                    if colors?
                      colors["tag_#{j}"] for j in [1..5]
                    else
                      []
                  child 'label.color-table-cell', key: "colors-#{i}", =>
                    child 'p', => raw colors?.name
                    child 'input',
                      ref: "colors_#{i}"
                      type: 'radio'
                      onChange: =>
                        game = update @props.game,
                          colors_id:
                            $set: do =>
                              for i in [1..6]
                                if @refs["colors_#{i}"].checked
                                  return i
                              1
                        @props.onChange game
                      name: 'colors'
                      checked: @props.game.colors_id is i
                    gradient = do =>
                      percent = 0
                      points = []
                      for rgb in rgbs
                        points.push "#{rgb} #{percent}%"
                        percent += 20
                        points.push "#{rgb} #{percent}%"
                      "linear-gradient(to right, #{points.join(', ')})"
                    child 'div.color-table-gradient', style:
                      backgroundImage: gradient
            colorsRow [1, 2, 3]
            colorsRow [4, 5, 6]

        child 'div.newStep1RightColumn'
      child 'div.bottom-step-buttons', =>
        child 'div'
        child 'a', href: '#categories' + @props.game.game_id, =>
          child 'div.newNextButton', =>
            raw 'categories >'

NewStep1 = React.createClass
  displayName: 'NewStep1'

  render: ->
    make 'div.newStepBox', =>
      child 'div.newStep1', =>
        child 'div.newStep1Column.newStep1LeftColumn', =>
          child 'h3', =>
            raw 'What kind of Siftr do you want to make?'
          child 'div', =>
            child 'label', =>
              child 'p', => raw 'NAME'
              child 'input.full-width-input',
                ref: 'name'
                type: 'text'
                value: @props.game.name ? ''
                onChange: @handleChange
            child 'label', =>
              child 'p', => raw 'SIFTR ICON'
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    @selectImage()
                child "div.siftr-icon-area.siftr-icon-#{if @props.icon? then 'filled' else 'empty'}", =>
                  if @props.icon?
                    props style:
                      backgroundImage: "url(#{@props.icon})"
                  else
                    child 'div.siftr-icon-gray-circle'
                    child 'h3', =>
                      raw 'Drag an image here or click to browse.'
                    child 'p', => child 'i', =>
                      raw '200px by 200px recommended'
                  props
                    onDragOver: (e) =>
                      e.stopPropagation()
                      e.preventDefault()
                    onDrop: (e) =>
                      e.stopPropagation()
                      e.preventDefault()
                      for file in e.dataTransfer.files
                        @loadImageFile file
                        break
            child 'label', =>
              child 'p', =>
                raw 'CATEGORIES '
                child 'i', => raw 'separated by comma'
              child 'input.full-width-input',
                ref: 'tag_string'
                type: 'text'
                value: @props.tag_string ? ''
                onChange: @handleChange
            child 'label', =>
              child 'p', =>
                raw 'DESCRIPTION '
                child 'a', href: 'https://daringfireball.net/projects/markdown/syntax', target: '_blank', =>
                  child 'i', => raw 'markdown supported'
              child 'textarea.full-width-textarea',
                ref: 'description'
                value: @props.game.description ? ''
                onChange: @handleChange
            child 'div',
              dangerouslySetInnerHTML: renderMarkdown @props.game.description
        child 'div.newStep1Column.newStep1RightColumn'
      child 'div.bottom-step-buttons', =>
        child 'div'
        child 'a', href: '#new2', =>
          child 'div.newNextButton', =>
            raw 'appearance >'

  selectImage: ->
    input = document.createElement 'input'
    input.type = 'file'
    input.onchange = (e) => @loadImageFile e.target.files[0]
    input.click()

  loadImageFile: (file) ->
    fr = new FileReader
    fr.onload = =>
      @props.onIconChange fr.result
    fr.readAsDataURL file

  handleChange: ->
    game = update @props.game,
      name:
        $set: @refs.name.value
      description:
        $set: @refs.description.value
    tag_string = @refs.tag_string.value
    @props.onChange(game, tag_string)

NewStep2 = React.createClass
  displayName: 'NewStep2'

  render: ->
    make 'div.newStepBox', =>

      child 'div.newStep2', =>
        child 'h3', =>
          raw 'Choose a color scheme for your new Siftr!'
        @tag_boxes = []
        child 'div.color-table', =>
          colorsRow = (colors_ids) =>
            for i in colors_ids
              colors = @props.colors[i]
              rgbs =
                if colors?
                  colors["tag_#{j}"] for j in [1..5]
                else
                  []
              child 'label.color-table-cell', key: "colors-#{i}", =>
                child 'p', => raw colors?.name
                child 'input', ref: "colors_#{i}", type: 'radio', onChange: @handleChange, name: 'colors', checked: @props.game.colors_id is i
                gradient = do =>
                  percent = 0
                  points = []
                  for rgb in rgbs
                    points.push "#{rgb} #{percent}%"
                    percent += 20
                    points.push "#{rgb} #{percent}%"
                  "linear-gradient(to right, #{points.join(', ')})"
                child 'div.color-table-gradient', style:
                  backgroundImage: gradient
          child 'div.color-table-row', => colorsRow [1, 2, 3]
          child 'div.color-table-row', => colorsRow [4, 5, 6]

        child 'div.newStep2LeftCol', =>
          child 'form', =>
            child 'h3', => raw 'CATEGORIES'
            for tag, i in @props.tag_string.split(',')
              tag = tag.replace(/^\s+/, '')
              do (i) =>
                child 'div.create-category-row', key: "tag-#{i}", =>
                  child 'span.create-category-dot', style:
                    backgroundColor: @props.colors[@props.game.colors_id]?["tag_#{(i % 8) + 1}"] or 'black'
                  child 'input.create-category-name',
                    type: 'text'
                    value: tag
                    onChange: @handleChange
                    ref: (elt) => @tag_boxes.push(elt) unless elt is null
                  child 'a', href: '#', =>
                    props
                      onClick: (e) =>
                        e.preventDefault()
                        @deleteTag i
                    child 'span.create-category-x', =>
                      raw '×'
            child 'p', =>
              child 'a', href: '#', =>
                props
                  onClick: (e) =>
                    e.preventDefault()
                    @addTag()
                child 'span.create-category-add', =>
                  raw 'ADD CATEGORY'

      child 'div.bottom-step-buttons', =>
        child 'a', href: '#new1', =>
          child 'div.newPrevButton', =>
            raw '< setup'
        child 'a', href: '#new3', =>
          child 'div.newNextButton', =>
            raw 'map >'

  deleteTag: (index) ->
    tags =
      for input, i in @tag_boxes
        continue if i is index
        input.value
    @props.onChange @props.game, tags.join(',')

  addTag: ->
    tag_string = @tag_boxes.map((input) => input.value).join(',') + ','
    @props.onChange @props.game, tag_string

  handleChange: ->
    colors_id = 1
    for i in [1..6]
      if @refs["colors_#{i}"].checked
        colors_id = i
    game = update @props.game,
      colors_id:
        $set: colors_id
    tag_string = @tag_boxes.map((input) => input.value).join(',')
    @props.onChange game, tag_string

NewStep3 = React.createClass
  displayName: 'NewStep3'

  shouldComponentUpdate: (nextProps, nextState) ->
    # This prevents the map from jerking back.
    # The number comparisons are needed due to tiny floating point errors.
    return true if @props.editing isnt nextProps.editing
    return true if Math.abs(@props.game.latitude - nextProps.game.latitude) > 0.0000001
    return true if Math.abs(@props.game.longitude - nextProps.game.longitude) > 0.0000001
    return true if @props.game.zoom isnt nextProps.game.zoom
    return true if @props.game.type isnt nextProps.game.type
    false

  render: ->
    make 'div.newStepBox', =>
      child 'div.newStep3', =>
        child 'div.newStep3Controls', =>
          child 'p', =>
            raw 'Is your Siftr tied to a specific location?'
          location = @props.game.type isnt 'ANYWHERE'
          child "a.form-multi-option.form-multi-option-#{if location then 'on' else 'off'}", href: '#', =>
            props
              onClick: (e) =>
                e.preventDefault()
                @props.onChange update @props.game, type: $set:
                  if location
                    'ANYWHERE'
                  else
                    'LOCATION'
            child 'span.form-multi-option-text', =>
              raw 'Load at location'
            child 'span.form-multi-option-switch', =>
              child 'span.form-multi-option-ball'
          child 'p', =>
            raw 'If not checked, your Siftr will zoom to show all the pins on the map.'
        child 'div.newStep3MapContainer', =>
          child GoogleMap,
            ref: 'map'
            bootstrapURLKeys:
              key: 'AIzaSyDlMWLh8Ho805A5LxA_8FgPOmnHI0AL9vw'
            center: [@props.game.latitude, @props.game.longitude]
            zoom: Math.max(2, @props.game.zoom)
            options: minZoom: 2
            onChange: @handleMapChange
      if @props.editing
        child 'div.bottom-step-buttons', =>
          child 'a', href: '#categories' + @props.game.game_id, =>
            child 'div.newPrevButton', =>
              raw '< categories'
          child 'a', href: '#form' + @props.game.game_id, =>
            child 'div.newNextButton', =>
              raw 'data >'
      else
        child 'div.bottom-step-buttons', =>
          child 'a', href: '#new2', =>
            child 'div.newPrevButton', =>
              raw '< appearance'
          child 'a', href: '#new4', =>
            child 'div.newNextButton', =>
              raw 'data >'

  handleMapChange: ({center: {lat, lng}, zoom}) ->
    game = update @props.game,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
    @props.onChange game

NewStep4 = React.createClass
  displayName: 'NewStep4'

  getInitialState: ->
    editingIndex: null
    editingField: null
    deletingOption: null

  reorderFields: (indexes) ->
    if @props.editing
      @props.reorderFields indexes, =>
        if @state.editingIndex?
          @setState
            editingIndex: indexes[@state.editingIndex]
    else
      if @state.editingIndex?
        @setState
          editingIndex: indexes[@state.editingIndex]
      @props.onChange update @props.game, fields: $set:
        for i in [0 .. indexes.length - 1]
          @props.game.fields[indexes[i]]

  reorderFieldOptions: (indexes, cb) ->
    if @props.editing
      @props.reorderFieldOptions @state.editingField, indexes, cb
    else
      @setState
        editingField:
          update @state.editingField, options: $set:
            for i in [0 .. indexes.length - 1]
              @state.editingField.options[indexes[i]]

  render: ->
    make 'div.newStepBox', =>
      fields =
        if @props.editing
          @props.fields ? []
        else
          @props.game.fields ? []
      makeArrow = (dir, enabled, wrap) =>
        src = "../assets/icons/arrow-#{dir}.png"
        if enabled
          wrap =>
            child 'img.sort-arrow', {src}
        else
          child 'img.sort-arrow.sort-arrow-disabled', {src}
      child 'div.newStep4', =>
        child 'div.newStep4Fields', =>
          fields.forEach (field, i) =>
            divFormFieldRow = 'div.form-field-row'
            if i is @state.editingIndex
              divFormFieldRow += '.form-field-row-selected'
            child divFormFieldRow, key: field.field_id, =>
              child 'div.form-field-icon', =>
                child 'img',
                  src: "../assets/icons/form-#{field.field_type}.png"
              child 'a.form-field-name', href: '#', onClick: (e) =>
                e.preventDefault()
                @setState
                  editingField: field
                  editingIndex: i
                  deletingOption: null
              , =>
                raw(field.label or 'Unnamed field')
                raw ' *' if field.required
              child 'div.form-field-x', =>
                makeArrow 'up', i isnt 0, (f) =>
                  child 'a', href: '#', onClick: ((e) =>
                    e.preventDefault()
                    e.stopPropagation()
                    @reorderFields(
                      for j in [0 .. fields.length - 1]
                        if j is i
                          j - 1
                        else if j is i - 1
                          j + 1
                        else
                          j
                    )
                  ), f
                makeArrow 'down', i isnt fields.length - 1, (f) =>
                  child 'a', href: '#', onClick: ((e) =>
                    e.preventDefault()
                    e.stopPropagation()
                    @reorderFields(
                      for j in [0 .. fields.length - 1]
                        if j is i
                          j + 1
                        else if j is i + 1
                          j - 1
                        else
                          j
                    )
                  ), f
                child 'a', href: '#', onClick: ((e) =>
                  e.preventDefault()
                  e.stopPropagation()
                  if @props.editing
                    if confirm "Are you sure you want to delete the #{field.label or 'unnamed'} field?"
                      @props.deleteField(field)
                  else
                    newFields = fields[..]
                    newFields.splice(i, 1)
                    @props.onChange update @props.game, fields: $set: newFields
                    if i < @state.editingIndex
                      @setState
                        editingIndex: @state.editingIndex - 1
                    else if i == @state.editingIndex
                      @setState
                        editingIndex: null
                        editingField: null
                ), =>
                  child 'span.deleterow', =>
                    raw 'delete'
          child 'p', => raw 'Add new field:'
          child 'p', =>
            types = [
              ['TEXT', 'small text field']
              ['TEXTAREA', 'large text field']
              ['SINGLESELECT', 'select one']
              ['MULTISELECT', 'select many']
              ['MEDIA', 'extra photo']
            ]
            types.forEach ([type, name], i) =>
              child 'a.form-add-field', href: '#', onClick: ((e) =>
                e.preventDefault()
                if @props.editing
                  @props.addField type
                else
                  @props.onChange update @props.game,
                    fields:
                      $set:
                        fields.concat [
                          new Field
                            field_type: type
                            label: ''
                            required: false
                            field_id: Date.now() # temporary, to use as React key
                        ]
              ), =>
                child 'img', src: "../assets/icons/form-#{type}.png"
                child 'br'
                raw name
        child 'div.newStep4FieldInfo', =>
          if (field = @state.editingField)?

            reloadThisField = =>
              for f, i in @props.fields
                if f.field_id is field.field_id
                  @setState
                    editingField: f
                    editingIndex: i
                    deletingOption: null
                  return

            if @state.deletingOption?
              child 'p', =>
                raw "Should data be reassigned from '#{@state.deletingOption.option}' to a different option?"
              confirmDelete = (new_option) =>
                msg =
                  if new_option?
                    "Are you sure you want to delete the option '#{@state.deletingOption.option}' and reassign its notes to '#{new_option.option}'?"
                  else
                    "Are you sure you want to delete the option '#{@state.deletingOption.option}'?"
                if confirm msg
                  @props.deleteFieldOption
                    field_option: @state.deletingOption
                    new_field_option: new_option
                  , reloadThisField
              child 'ul', =>
                (field.options ? []).forEach (o) =>
                  unless o.field_option_id is @state.deletingOption.field_option_id
                    child 'li', key: o.field_option_id, =>
                      child 'a', href: '#', onClick: (e) =>
                        e.preventDefault()
                        confirmDelete o
                      , =>
                        raw o.option
              child 'p', =>
                child 'a', href: '#', onClick: (e) =>
                  e.preventDefault()
                  confirmDelete null
                , =>
                  raw "Don't reassign"
              child 'p', =>
                child 'a', href: '#', onClick: (e) =>
                  e.preventDefault()
                  @setState deletingOption: null
                , =>
                  raw "Cancel"
            else
              child 'div.inspectortitle', =>
                child 'img.inspectoricon', src: "../assets/icons/form-#{field.field_type}.png"
                child 'h2', =>
                  switch field.field_type
                    when 'TEXT'
                      raw 'Small text field'
                    when 'TEXTAREA'
                      raw 'Large text field'
                    when 'MEDIA'
                      raw 'Image upload'
                    when 'SINGLESELECT'
                      raw 'Select one'
                    when 'MULTISELECT'
                      raw 'Select Many'
              child 'div.inspector-question', =>
                child 'input',
                  type: 'textarea'
                  value: field.label
                  placeholder: 'What Question are you asking?'
                  onChange: (e) =>
                    @setState
                      editingField:
                        update field, label: $set: e.target.value
              unless field.field_type in ['SINGLESELECT', 'MULTISELECT']
                child 'p', =>
                  child 'label', =>
                    child 'input',
                      type: 'checkbox'
                      checked: field.required
                      onChange: (e) =>
                        @setState
                          editingField:
                            update field, required: $set: e.target.checked
                    raw ' Required'
              if @props.editing
                child 'p', =>
                  child 'button',
                    type: 'button'
                    onClick: =>
                      @props.updateField field
                      @setState
                        editingField: null
                        editingIndex: null
                  , =>
                    raw 'Save'
              if field.field_type in ['SINGLESELECT', 'MULTISELECT']
                options = field.options ? []
                child 'ul', =>
                  options.forEach (o, i) =>
                    child 'li', key: o.field_option_id, =>
                      makeArrow 'up', i isnt 0, (f) =>
                        child 'a', href: '#', onClick: ((e) =>
                          e.preventDefault()
                          indexes =
                            for j in [0 .. options.length - 1]
                              if j is i
                                j - 1
                              else if j is i - 1
                                j + 1
                              else
                                j
                          @reorderFieldOptions indexes, reloadThisField
                        ), f
                      makeArrow 'down', i isnt options.length - 1, (f) =>
                        child 'a', href: '#', onClick: ((e) =>
                          e.preventDefault()
                          indexes =
                            for j in [0 .. options.length - 1]
                              if j is i
                                j + 1
                              else if j is i + 1
                                j - 1
                              else
                                j
                          @reorderFieldOptions indexes, reloadThisField
                        ), f
                      if @props.editing
                        child 'input',
                          type: 'text'
                          defaultValue: o.option
                          onChange: (e) =>
                            @props.updateFieldOption
                              field_option: o
                              option: e.target.value
                            , reloadThisField
                      else
                        child 'input',
                          type: 'text'
                          value: o.option
                          onChange: (e) =>
                            opts = options[..]
                            opts.splice(i, 1, update(o, option: $set: e.target.value))
                            @setState
                              editingField:
                                update field, options: $set: opts
                      child 'a', href: '#', onClick: ((e) =>
                        e.preventDefault()
                        if @props.editing
                          @setState
                            deletingOption: o
                        else
                          opts = options[..]
                          opts.splice(i, 1)
                          @setState
                            editingField:
                              update field, options: $set: opts
                      ), =>
                        child 'img.deletefield', src: '../assets/icons/deletefield.png'
                  child 'li', =>
                    child 'a', onClick: (=>
                      if @props.editing
                        @props.addFieldOption
                          field: field
                          option: ''
                        , reloadThisField
                      else
                        @setState
                          editingField:
                            update field, options: $set: options.concat([{option: '', field_option_id: Date.now()}])
                    ), =>
                      child 'span.addoption_btn', =>
                        child 'img.addoption', src: '../assets/icons/addfield.png'
                        raw 'add answer'
              unless @props.editing
                child 'p.savebutton', =>
                  child 'span.button',
                    onClick: =>
                      @props.onChange update @props.game,
                        fields: singleObj(@state.editingIndex, {$set: field})
                      @setState
                        editingField: null
                        editingIndex: null
                  , =>
                    raw 'Save field'
          else
            child 'p', =>
              raw 'No field selected.'

      if @props.editing
        child 'div.bottom-step-buttons', =>
          child 'a', href: '#map' + @props.game.game_id, =>
            child 'div.newPrevButton', =>
              raw '< map'
          child 'div'
      else
        child 'div.bottom-step-buttons', =>
          child 'a', href: '#new3', =>
            child 'div.newPrevButton', =>
              raw '< map'
          child 'a', href: '#new5', =>
            child 'div.newNextButton', =>
              raw 'settings >'

NewStep5 = React.createClass
  displayName: 'NewStep5'

  render: ->
    make 'div.newStepBox', =>
      child 'div.newStep1', =>
        child 'div.newStep1Column.newStep1LeftColumn', =>
          child 'h4', => raw 'PRIVACY'

          hidden = not @props.game.published
          child "a.form-multi-option.form-multi-option-#{if hidden then 'on' else 'off'}", href: '#', =>
            props
              onClick: (e) =>
                e.preventDefault()
                @props.onChange update @props.game, published: $set: hidden
            child 'span.form-multi-option-text', =>
              raw 'Hide from search'
            child 'span.form-multi-option-switch', =>
              child 'span.form-multi-option-ball'
          child 'p', =>
            raw 'Do you want to set a password to restrict access?'
          child 'p', =>
            child 'input.full-width-input',
              type: 'text'
              placeholder: 'Password (optional)'
              value: @props.game.password ? ''
              onChange: (e) => @props.onChange update @props.game, password: $set: e.target.value
          moderated = @props.game.moderated
          child "a.form-multi-option.form-multi-option-#{if moderated then 'on' else 'off'}", href: '#', =>
            props
              onClick: (e) =>
                e.preventDefault()
                @props.onChange update @props.game, moderated: $set: not moderated
            child 'span.form-multi-option-text', =>
              raw 'Require moderation?'
            child 'span.form-multi-option-switch', =>
              child 'span.form-multi-option-ball'
          child 'h4', => raw 'URL'
          child 'p', =>
            child 'input.full-width-input',
              type: 'text'
              placeholder: 'URL (optional)'
              value: @props.game.siftr_url ? ''
              onChange: (e) => @props.onChange update @props.game, siftr_url: $set: e.target.value
          child 'p', =>
            if @props.game.siftr_url
              child 'b', => raw @props.game.name
              raw " will be located at "
              child 'code', => raw "#{SIFTR_URL}#{@props.game.siftr_url}"
            else
              raw "Enter a custom identifier for your Siftr's web address."
        child 'div.newStep1Column.newStep1RightColumn'
      child 'div.bottom-step-buttons', =>
        child 'a', href: '#new4', =>
          child 'div.newPrevButton', =>
            raw '< data'
        child 'a', href: "#", =>
          props
            onClick: (e) =>
              e.preventDefault()
              @props.onCreate()
          child 'div.newNextButton', =>
            raw 'publish!'

document.addEventListener 'DOMContentLoaded', (event) ->
  ReactDOM.render make(App, aris: new Aris), document.getElementById('the-container')
