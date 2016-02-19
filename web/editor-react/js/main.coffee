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

ifCordova = (cordovaLink, normalLink) ->
  if window.cordova?
    cordovaLink
  else
    normalLink

countContributors = (notes) ->
  user_ids = {}
  for note in notes
    user_ids[note.user.user_id] = true
    for comment in note.comments
      user_ids[comment.user.user_id] = true
  Object.keys(user_ids).length

App = React.createClass
  displayName: 'App'

  getInitialState: ->
    auth: null
    games: []
    tags: {}
    notes: {}
    colors: {}
    username: ''
    password: ''
    screen: 'main'
    edit_game: null
    new_game: do =>
      g = new Game
      g.colors_id = 1
      g.latitude = 43
      g.longitude = -89
      g.zoom = 14
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
    else if hash is 'new1'
      @setState
        screen: 'new1'
        new_step: 1
    else if hash is 'new2'
      if @state.new_step is null
        window.location.replace '#new1'
      else
        @setState
          screen: 'new2'
          new_step: 2
    else if hash is 'new3'
      if @state.new_step in [null, 1]
        window.location.replace '#new1'
      else
        @setState
          screen: 'new3'
          new_step: 3
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
          @setState
            games:
              game for game in result.data when game.is_siftr
            tags: {}
            notes: {}
          @applyHash()
          @updateTags result.data
          @updateNotes result.data
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
        @setState (previousState, currentProps) =>
          update previousState,
            notes:
              $merge: singleObj(newGame.game_id, [])
            new_game:
              $set: do =>
                g = new Game
                g.colors_id = 1
                g.latitude = 43
                g.longitude = -89
                g.zoom = 14
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

  render: ->
    make "div.topDiv.accountMenu#{if @state.account_menu then 'Open' else 'Closed'}", =>
      child 'div#the-nav-bar', =>
        child 'div#the-mobile-menu-button', =>
          props
            onClick: => @setState account_menu: not @state.account_menu
            style: cursor: 'pointer'
          raw '☰'
        child 'a', href: ifCordova('../index.html', '..'), =>
          child 'img#the-logo', src: 'img/brand.png'
        child 'a', href: ifCordova('../discover/index.html', '../discover'), =>
          child 'div#the-discover-button', =>
            raw 'Discover'
        if @state.auth?
          child 'div#the-my-account-button', =>
            props
              onClick: => @setState account_menu: not @state.account_menu
              style: cursor: 'pointer'
            raw 'My Account'
        child 'a', href: '../editor', =>
          child 'div#the-my-siftrs-button', =>
            raw 'My Siftrs'
      child 'div#the-content', =>
        if @state.auth?
          child 'div', =>
            switch @state.screen
              when 'account'
                child 'div.loginForm', =>
                  props style: textAlign: 'center'
                  child 'h3', =>
                    raw 'Account Details'
                  child 'p', =>
                    child 'span',
                      style:
                        width: 200
                        height: 200
                        borderRadius: 100
                        backgroundColor: 'black'
                        backgroundImage:
                          if @state.new_icon?
                            "url(#{@state.new_icon})"
                          else if @state.userPicture?
                            "url(#{@state.userPicture.url})"
                          else
                            undefined
                        backgroundSize: 'cover'
                        display: 'inline-block'
                        cursor: 'pointer'
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
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                        cursor: 'pointer'
                        marginBottom: 30
                      onClick: @logout
                    raw 'LOGOUT'
                  child 'p', =>
                    child 'input',
                      autoCapitalize: 'off'
                      autoCorrect: 'off'
                      type: 'text'
                      placeholder: 'Display Name'
                      value: @state.display_name
                      style: width: '100%'
                      onChange: (e) => @setState display_name: e.target.value
                  child 'p', =>
                    child 'input',
                      autoCapitalize: 'off'
                      autoCorrect: 'off'
                      type: 'text'
                      placeholder: 'Email'
                      value: @state.email
                      style: width: '100%'
                      onChange: (e) => @setState email: e.target.value
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                        cursor: 'pointer'
                        marginBottom: 15
                      onClick: =>
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
                    raw 'SAVE CHANGES'
                  child 'a', href: '#', =>
                    child 'div', =>
                      props
                        style:
                          backgroundColor: 'rgb(51,191,224)'
                          width: '100%'
                          paddingTop: 8
                          paddingBottom: 8
                          textAlign: 'center'
                          color: 'white'
                      raw 'BACK'
                  child 'h3', =>
                    raw 'Change Password'
                  child 'p', =>
                    child 'input',
                      autoCapitalize: 'off'
                      autoCorrect: 'off'
                      type: 'password'
                      placeholder: 'Old password'
                      value: @state.old_password
                      style: width: '100%'
                      onChange: (e) => @setState old_password: e.target.value
                  child 'p', =>
                    child 'input',
                      autoCapitalize: 'off'
                      autoCorrect: 'off'
                      type: 'password'
                      placeholder: 'New password'
                      value: @state.password
                      style: width: '100%'
                      onChange: (e) => @setState password: e.target.value
                  child 'p', =>
                    child 'input',
                      autoCapitalize: 'off'
                      autoCorrect: 'off'
                      type: 'password'
                      placeholder: 'Repeat new password'
                      value: @state.password2
                      style: width: '100%'
                      onChange: (e) => @setState password2: e.target.value
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                        cursor: 'pointer'
                        marginBottom: 15
                      onClick: =>
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
                    raw 'CHANGE PASSWORD'
              when 'edit'
                child EditSiftr,
                  game: @state.edit_game
                  colors: @state.colors
                  onChange: (game) => @setState edit_game: game
                  onSave: @handleSave
                  mobileMapIsOpen: @state.mobile_map_is_open
                  openMobileMap: =>
                    @setState mobile_map_is_open: true
                    setTimeout =>
                      window.dispatchEvent new Event 'resize'
                    , 250
                  closeMobileMap: => @setState mobile_map_is_open: false
              when 'categories'
                child 'div.loginForm', =>
                  tags = @state.tags[@state.edit_game.game_id]
                  colors = @state.colors[@state.edit_game.colors_id or 1]
                  child 'h2', =>
                    props style:
                      textAlign: 'center'
                      marginBottom: 40
                    raw "Categories for "
                    child 'b', =>
                      raw @state.edit_game.name
                  if not tags?
                    child 'p', style: {textAlign: 'center'}, =>
                      raw 'Loading categories...'
                  else if @state.delete_tag?
                    child 'h4', =>
                      props
                        style:
                          textAlign: 'center'
                          padding: 20
                      raw "Choose a category to reassign all #{@state.delete_tag.tag} notes to."
                    for tag, i in tags
                      continue if tag is @state.delete_tag
                      do (tag, i) =>
                        child 'div', =>
                          color = colors["tag_#{(i % 8) + 1}"]
                          props
                            style:
                              backgroundColor: color
                              color: 'white'
                              boxSizing: 'border-box'
                              width: '100%'
                              padding: 10
                              fontSize: 20
                              marginTop: 10
                              textAlign: 'center'
                              borderRadius: 5
                              cursor: 'pointer'
                              position: 'relative'
                            onClick: =>
                              if confirm "Are you sure you want to delete the category \"#{@state.delete_tag.tag}\" and move all its notes to \"#{tag.tag}\"?"
                                @props.aris.call 'tags.deleteTag',
                                  tag_id: @state.delete_tag.tag_id
                                  new_tag_id: tag.tag_id
                                , =>
                                  @setState delete_tag: null
                                  @updateTags [@state.edit_game]
                          raw tag.tag
                    child 'div', =>
                      props
                        style:
                          backgroundColor: 'rgb(97,201,226)'
                          color: 'white'
                          padding: 10
                          fontSize: 20
                          marginTop: 40
                          textAlign: 'center'
                          cursor: 'pointer'
                        onClick: => @setState delete_tag: null
                      raw 'CANCEL'
                  else
                    for tag, i in tags
                      do (tag, i) =>
                        child 'div', =>
                          color = colors["tag_#{(i % 8) + 1}"]
                          props
                            style:
                              backgroundColor: color
                              color: 'white'
                              boxSizing: 'border-box'
                              width: '100%'
                              padding: 10
                              fontSize: 20
                              marginTop: 10
                              textAlign: 'center'
                              borderRadius: 5
                              cursor: 'pointer'
                              position: 'relative'
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
                          child 'div', =>
                            props
                              style:
                                position: 'absolute'
                                right: 8
                                top: 4
                                padding: '4px 10px'
                                boxSizing: 'border-box'
                                border: '2px solid white'
                              onClick: (e) =>
                                e.stopPropagation()
                                @setState delete_tag: tag
                            raw 'X'
                    child 'div', =>
                      props
                        style:
                          backgroundColor: 'rgb(97,201,226)'
                          color: 'white'
                          padding: 10
                          fontSize: 20
                          marginTop: 40
                          cursor: 'pointer'
                          textAlign: 'center'
                        onClick: =>
                          str = prompt "Enter a new category..."
                          if str? and str isnt ''
                            tagObject = new Tag
                            tagObject.tag = str
                            tagObject.game_id = @state.edit_game.game_id
                            @props.aris.createTag tagObject, =>
                              @updateTags [@state.edit_game]
                      raw 'NEW CATEGORY'
                    child 'a', href: '#', =>
                      child 'div', =>
                        props
                          style:
                            backgroundColor: 'rgb(97,201,226)'
                            color: 'white'
                            padding: 10
                            fontSize: 20
                            marginTop: 10
                            textAlign: 'center'
                        raw 'BACK'
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
                  onCreate: @createGame
              else
                child 'div', =>
                  child 'p', style: {textAlign: 'center', paddingTop: 25}, =>
                    child 'a', href: '#new1', =>
                      child 'span', =>
                        props style:
                          backgroundColor: 'rgb(51,191,224)'
                          color: 'white'
                          paddingLeft: 40
                          paddingRight: 40
                          paddingTop: 10
                          paddingBottom: 10
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
            child 'div', style: {textAlign: 'center'}, =>
              child 'a.unlink', href: '#account', =>
                child 'p', =>
                  child 'span', style:
                    width: 100
                    height: 100
                    borderRadius: 50
                    backgroundColor: 'white'
                    backgroundImage: if @state.userPicture? then "url(#{@state.userPicture.thumb_url})" else undefined
                    backgroundSize: 'cover'
                    display: 'inline-block'
                child 'p', =>
                  raw @state.auth.display_name
                child 'div', =>
                  props
                    style:
                      width: '100%'
                      boxSizing: 'border-box'
                      textAlign: 'center'
                      padding: 5
                      marginBottom: 12
                      backgroundColor: 'rgb(51,191,224)'
                  raw 'ACCOUNT SETTINGS'
              child 'div', =>
                props
                  style:
                    width: '100%'
                    boxSizing: 'border-box'
                    textAlign: 'center'
                    cursor: 'pointer'
                    padding: 5
                    marginBottom: 12
                    backgroundColor: 'rgb(51,191,224)'
                  onClick: @logout
                raw 'LOGOUT'
        else
          switch @state.screen
            when 'forgot'
              child 'div.loginForm', =>
                child 'p', style: {textAlign: 'center'}, =>
                  raw 'Enter your username '
                  child 'b', => raw 'or'
                  raw ' email to reset your password.'
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username
                    style: width: '100%'
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @sendPasswordReset()
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Email'
                    value: @state.email
                    style: width: '100%'
                    onChange: (e) => @setState email: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @sendPasswordReset()
                child 'div', =>
                  props
                    style:
                      backgroundColor: 'rgb(51,191,224)'
                      width: '100%'
                      paddingTop: 8
                      paddingBottom: 8
                      textAlign: 'center'
                      color: 'white'
                      cursor: 'pointer'
                      marginBottom: 15
                    onClick: =>
                      @sendPasswordReset()
                  raw 'SEND EMAIL'
                child 'a', href: '#', =>
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                    raw 'BACK'
            when 'signup'
              child 'div.loginForm', =>
                child 'p', style: {textAlign: 'center'}, =>
                  raw 'Create a new Siftr account'
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Email'
                    value: @state.email
                    style: width: '100%'
                    onChange: (e) => @setState email: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username
                    style: width: '100%'
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Password'
                    value: @state.password
                    style: width: '100%'
                    onChange: (e) => @setState password: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Repeat password'
                    value: @state.password2
                    style: width: '100%'
                    onChange: (e) => @setState password2: e.target.value
                    onKeyDown: (e) =>
                      @signup() if e.keyCode is 13
                child 'div', =>
                  props
                    style:
                      backgroundColor: 'rgb(51,191,224)'
                      width: '100%'
                      paddingTop: 8
                      paddingBottom: 8
                      textAlign: 'center'
                      color: 'white'
                      cursor: 'pointer'
                      marginBottom: 15
                    onClick: @signup
                  raw 'CREATE ACCOUNT'
                child 'a', href: '#', =>
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                    raw 'BACK'
            else
              child 'div.loginForm', =>
                child 'p', style: {textAlign: 'center'}, =>
                  raw 'Login with a Siftr or ARIS account'
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'text'
                    placeholder: 'Username'
                    value: @state.username
                    style: width: '100%'
                    onChange: (e) => @setState username: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @login @state.username, @state.password
                child 'p', =>
                  child 'input',
                    autoCapitalize: 'off'
                    autoCorrect: 'off'
                    type: 'password'
                    placeholder: 'Password'
                    value: @state.password
                    style: width: '100%'
                    onChange: (e) => @setState password: e.target.value
                    onKeyDown: (e) =>
                      if e.keyCode is 13
                        @login @state.username, @state.password
                child 'div', =>
                  props
                    style:
                      backgroundColor: 'rgb(51,191,224)'
                      width: '100%'
                      paddingTop: 8
                      paddingBottom: 8
                      textAlign: 'center'
                      color: 'white'
                      cursor: 'pointer'
                      marginBottom: 15
                    onClick: =>
                      @login @state.username, @state.password
                  raw 'LOGIN'
                child 'a', href: '#signup', =>
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                        marginBottom: 15
                    raw 'CREATE ACCOUNT'
                child 'a', href: '#forgot', =>
                  child 'div', =>
                    props
                      style:
                        backgroundColor: 'rgb(51,191,224)'
                        width: '100%'
                        paddingTop: 8
                        paddingBottom: 8
                        textAlign: 'center'
                        color: 'white'
                    raw 'FORGOT PASSWORD?'
      child 'div.accountMenuMobile', =>
        child 'span', =>
          props
            onClick: => @setState account_menu: false
        child 'div', =>
          child 'img',
            src: '../client-react/img/x-white.png'
            style: cursor: 'pointer'
            onClick: => @setState account_menu: false
        child 'div', style: {textAlign: 'center'}, =>
          if @state.auth?
            child 'a.unlink', href: '#account', =>
              child 'p', =>
                child 'span', style:
                  width: 80
                  height: 80
                  borderRadius: 40
                  backgroundColor: 'white'
                  backgroundImage: if @state.userPicture? then "url(#{@state.userPicture.thumb_url})" else undefined
                  backgroundSize: 'cover'
                  display: 'inline-block'
              child 'p', => raw @state.auth.display_name
          else
            child 'p', => raw 'Not logged in'
          child 'p', =>
            child 'a', href: ifCordova('../index.html', '..'), =>
              child 'img', src: '../client-react/img/brand-mobile.png'
          unlink =
            color: 'white'
            textDecoration: 'none'
          child 'p', => child 'a', style: unlink, href: ifCordova('../editor-react/index.html', '../editor'), => raw 'My Siftrs'
          child 'p', => child 'a', style: unlink, href: ifCordova('../discover/index.html', '../discover'), => raw 'Discover'
          if @state.auth?
            child 'p', style: {cursor: 'pointer'}, onClick: @logout, => raw 'Logout'

SiftrList = React.createClass
  displayName: 'SiftrList'

  render: ->
    make 'div.siftrList', =>
      @props.games.forEach (game) =>
        notes = @props.notes[game.game_id]
        child 'div', key: "game-#{game.game_id}", =>
          props
            style:
              marginBottom: 50
          child 'div', =>
            props
              style:
                marginBottom: 10
            child 'a', href: ifCordova("../client-react/index.html?#{game.siftr_url or game.game_id}", "#{SIFTR_URL}#{game.siftr_url or game.game_id}"), target: ifCordova('', '_blank'), =>
              props
                style:
                  float: 'left'
                  fontSize: '23px'
                  color: 'black'
              raw game.name
            child 'div.clearOnMobile'
            child 'span', =>
              props
                style:
                  float: 'right'
                  border: '1px solid black'
                  padding: 5
                  marginLeft: 5
                  color: 'black'
                  cursor: 'pointer'
                onClick: =>
                  if confirm "Are you sure you want to delete \"#{game.name}\"?"
                    @props.onDelete game
              raw 'DELETE'
            child 'a', href: "\#categories#{game.game_id}", =>
              child 'span', =>
                props
                  style:
                    float: 'right'
                    border: '1px solid black'
                    padding: 5
                    marginLeft: 5
                    color: 'black'
                raw 'CATEGORIES'
            child 'a', href: "\#edit#{game.game_id}", =>
              child 'span', =>
                props
                  style:
                    float: 'right'
                    border: '1px solid black'
                    padding: 5
                    marginLeft: 5
                    color: 'black'
                raw 'EDIT'
            child 'div', style: clear: 'both'
          child 'div', =>
            props
              style:
                width: '100%'
                height: '10px'
                margin: 0
                padding: 0
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
          child 'div', =>
            props
              style:
                marginTop: 10
            sep = => child 'span', style: {marginLeft: 20, marginRight: 20}, => raw ' | '
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
    make 'div', =>
      if @props.mobileMapIsOpen
        props className: 'mobileMapIsOpen'
      child 'div', =>
        child 'div.editSiftrLeftCol', =>
          child 'form', =>
            child 'h2', => raw @props.game.name
            child 'label', =>
              child 'h4', => raw 'NAME'
              child 'input', ref: 'name', type: 'text', value: @props.game.name, onChange: @handleChange, style: {width: '100%'}
            child 'label', =>
              child 'h4', =>
                raw 'DESCRIPTION '
                child 'a', href: 'https://daringfireball.net/projects/markdown/syntax', target: '_blank', =>
                  child 'i', => raw 'markdown supported'
              child 'textarea', ref: 'description', value: @props.game.description, onChange: @handleChange, style: {width: '100%', height: 105}
            child 'div',
              dangerouslySetInnerHTML: renderMarkdown @props.game.description
            child 'label', =>
              child 'h4', => raw 'URL'
              child 'p', =>
                child 'input',
                  type: 'text'
                  placeholder: 'URL (optional)'
                  value: @props.game.siftr_url
                  onChange: (e) => @props.onChange update @props.game, siftr_url: $set: e.target.value
                  style: width: '100%'
            child 'p', =>
              child 'b', => raw @props.game.name
              raw " will be located at "
              child 'code', => raw "#{SIFTR_URL}#{@props.game.siftr_url ? @props.game.game_id}"
            child 'label', =>
              child 'h4', => raw 'PROMPT'
              child 'p', =>
                raw 'Enter a caption prompt for a user uploading a photo.'
              child 'p', =>
                child 'input',
                  type: 'text'
                  placeholder: 'Enter a caption...'
                  value: @props.game.prompt
                  onChange: (e) => @props.onChange update @props.game, prompt: $set: e.target.value
                  style: width: '100%'
            child 'p.editLocationMobile', =>
              props style:
                marginTop: 30
                marginBottom: 30
              child 'span', =>
                props
                  style:
                    backgroundColor: 'rgb(51,191,224)'
                    color: 'white'
                    cursor: 'pointer'
                    paddingLeft: 35
                    paddingRight: 35
                    paddingTop: 10
                    paddingBottom: 10
                  onClick: @props.openMobileMap
                raw 'EDIT LOCATION'
            child 'h2', => raw 'SETTINGS'
            child 'h4', => raw 'PRIVACY'
            child 'p', =>
              raw 'Do you want '
              child 'b', => raw @props.game.name
              raw ' to be public or private?'
            button = (str, checked, check) =>
              child 'span', =>
                props
                  style:
                    boxSizing: 'border-box'
                    width: 120
                    padding: 10
                    display: 'inline-block'
                    textAlign: 'center'
                    border: '3px solid rgb(51,191,224)'
                    cursor: 'pointer'
                    # TODO: ask Eric if the below colors are right, or if they should be flipped
                    color: if checked then 'white' else 'rgb(51,191,224)'
                    backgroundColor: if checked then 'rgb(51,191,224)' else 'white'
                  onClick: check
                raw str
            child 'p', =>
              props style:
                marginTop: 30
                marginBottom: 30
              button 'PUBLIC', @props.game.published, =>
                @props.onChange update @props.game, published: $set: true
              button 'PRIVATE', not @props.game.published, =>
                @props.onChange update @props.game, published: $set: false
            child 'h4', => raw 'MODERATION'
            child 'p', =>
              raw 'Do new user submissions have to be approved by you before they are added to '
              child 'b', => raw @props.game.name
              raw '?'
            child 'p', =>
              props style:
                marginTop: 30
                marginBottom: 30
              button 'YES', @props.game.moderated, =>
                @props.onChange update @props.game, moderated: $set: true
              button 'NO', not @props.game.moderated, =>
                @props.onChange update @props.game, moderated: $set: false

            child 'h2', => raw 'APPEARANCE'
            child 'p', =>
              raw 'What color palette should '
              child 'b', => raw @props.game.name
              raw ' use?'
            colorsRow = (colors_ids) =>
              child 'div', =>
                props style:
                  display: 'table'
                  width: '100%'
                  tableLayout: 'fixed'
                  fontSize: '13px'
                for i in colors_ids
                  colors = @props.colors[i]
                  rgbs =
                    if colors?
                      colors["tag_#{j}"] for j in [1..5]
                    else
                      []
                  child 'label', key: "colors-#{i}", =>
                    props style: display: 'table-cell'
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
                    child 'div', style:
                      width: 90
                      height: 35
                      marginLeft: 10
                      backgroundImage: gradient
                      display: 'inline-block'
            colorsRow [1, 2, 3]
            colorsRow [4, 5, 6]

            child 'p', =>
              props style:
                marginTop: 60
                marginBottom: 30
              child 'span', =>
                props
                  style:
                    backgroundColor: 'rgb(51,191,224)'
                    color: 'white'
                    cursor: 'pointer'
                    paddingLeft: 35
                    paddingRight: 35
                    paddingTop: 10
                    paddingBottom: 10
                    marginRight: 20
                  onClick: =>
                    unless @props.game.name
                      alert 'Please enter a name for your Siftr.'
                    else unless @props.game.description
                      alert 'Please enter a description for your Siftr.'
                    else
                      @props.onSave()
                raw 'SAVE'
              child 'a', href: '#', =>
                child 'span', =>
                  props style:
                    backgroundColor: 'lightgray'
                    color: 'white'
                    paddingLeft: 35
                    paddingRight: 35
                    paddingTop: 10
                    paddingBottom: 10
                    marginRight: 20
                  raw 'CANCEL'
        child 'div.editSiftrMapContainer', =>
          child GoogleMap,
            ref: 'map'
            center: [@props.game.latitude, @props.game.longitude]
            zoom: Math.max(2, @props.game.zoom)
            options: minZoom: 2
            onChange: @handleMapChange
          child 'span.mobileSaveLocation', onClick: @props.closeMobileMap, =>
            raw 'SAVE LOCATION'
        child 'div', style: clear: 'both'

  handleChange: ->
    game = update @props.game,
      name:
        $set: @refs['name'].value
      description:
        $set: @refs['description'].value
      colors_id:
        $set: do =>
          for i in [1..6]
            if @refs["colors_#{i}"].checked
              return i
          1
    @props.onChange game

  handleMapChange: ({center: {lat, lng}, zoom}) ->
    game = update @props.game,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
    @props.onChange game

NewStep1 = React.createClass
  displayName: 'NewStep1'

  render: ->
    make 'div', =>
      child 'div', =>
        props
          style:
            width: '100%'
            textAlign: 'center'
            backgroundColor: 'gray'
            color: 'white'
            paddingTop: 60
            paddingBottom: 60
            position: 'relative'
            backgroundImage: 'url(../assets/photos/siftr-header.jpg)'
            backgroundSize: 'cover'
            backgroundRepeat: 'no-repeat'
        child 'span', style: {fontSize: '30px'}, => raw 'NEW SIFTR'
        child 'div.newNextButton', =>
          props
            onClick: =>
              unless @props.game.name
                alert "Please give your Siftr a name."
              else unless @props.game.description
                alert "Please give your Siftr a description."
              else
                window.location.replace '#new2'
            style: cursor: 'pointer'
          raw 'NEXT, APPEARANCE >'

      child 'div.newStep1', =>
        child 'h3', style: {textAlign: 'center'}, =>
          raw 'What kind of Siftr do you want to make?'
        child 'div', =>
          child 'div.newStep1RightCol', =>
            child 'label', =>
              child 'p', => raw 'NAME'
              child 'input', ref: 'name', type: 'text', value: @props.game.name, onChange: @handleChange, style: {width: '100%'}
            child 'label', =>
              child 'p', =>
                raw 'CATEGORIES '
                child 'i', => raw 'separated by comma'
              child 'input', ref: 'tag_string', type: 'text', value: @props.tag_string, onChange: @handleChange, style: {width: '100%'}
            child 'label', =>
              child 'p', =>
                raw 'DESCRIPTION '
                child 'a', href: 'https://daringfireball.net/projects/markdown/syntax', target: '_blank', =>
                  child 'i', => raw 'markdown supported'
              child 'textarea', ref: 'description', value: @props.game.description, onChange: @handleChange, style: {width: '100%', height: 105}
            child 'div',
              dangerouslySetInnerHTML: renderMarkdown @props.game.description
          child 'div.newStep1LeftCol', =>
            child 'label', =>
              child 'p', => raw 'SIFTR ICON'
              child 'div', =>
                s =
                  width: '100%'
                  height: 260
                  cursor: 'pointer'
                  backgroundColor: '#eee'
                  textAlign: 'center'
                  boxSizing: 'border-box'
                if @props.icon?
                  props style: update s, $merge:
                    backgroundImage: "url(#{@props.icon})"
                    backgroundSize: 'contain'
                    backgroundRepeat: 'no-repeat'
                    backgroundPosition: 'center'
                else
                  props style: update s, $merge:
                    paddingLeft: 40
                    paddingRight: 40
                    paddingTop: 30
                  child 'div', style:
                    backgroundColor: '#ccc'
                    height: 80
                    width: 80
                    borderRadius: '40px'
                    marginLeft: 'auto'
                    marginRight: 'auto'
                  child 'h3', =>
                    raw 'Drag an image here or '
                    child 'span', style: {color: 'rgb(20,156,201)'}, => raw 'browse'
                    raw ' to upload one.'
                  child 'p', => child 'i', =>
                    raw '200px by 200px recommended'
                props
                  onClick: @selectImage
                  onDragOver: (e) =>
                    e.stopPropagation()
                    e.preventDefault()
                  onDrop: (e) =>
                    e.stopPropagation()
                    e.preventDefault()
                    for file in e.dataTransfer.files
                      @loadImageFile file
                      break

          child 'div', style: clear: 'both'
        child 'p', =>
          child 'a', href: '#', =>
            child 'span', =>
              props style:
                float: 'right'
                color: 'white'
                backgroundColor: 'lightgray'
                paddingLeft: 35
                paddingRight: 35
                paddingTop: 8
                paddingBottom: 8
              raw 'CANCEL'

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
    make 'div', =>
      child 'div', =>
        props
          style:
            width: '100%'
            textAlign: 'center'
            backgroundColor: 'gray'
            color: 'white'
            paddingTop: 60
            paddingBottom: 60
            position: 'relative'
            backgroundImage: 'url(../assets/photos/siftr-header.jpg)'
            backgroundSize: 'cover'
            backgroundRepeat: 'no-repeat'
        child 'span', style: {fontSize: '30px'}, => raw 'NEW SIFTR'
        child 'a', href: '#new1', =>
          child 'div.newPrevButton', =>
            raw '< BACK, SETUP'
        child 'div.newNextButton', =>
          props
            onClick: =>
              tags = @props.tag_string.split(',').map (t) => t.replace(/^\s+/, '')
              if tags.length is 1 and tags[0] is ''
                alert 'You must have at least one category.'
              else if '' in tags
                alert 'You cannot have any unnamed categories.'
              else
                window.location.replace '#new3'
            style: cursor: 'pointer'
          raw 'NEXT, SETTINGS >'

      child 'div.newStep2', =>
        child 'h3', style: {textAlign: 'center'}, =>
          raw 'Choose a color scheme for your new Siftr!'
        @tag_boxes = []
        child 'div.newStep2ColorTable', =>
          props style:
            display: 'table'
            width: '100%'
            tableLayout: 'fixed'
            fontSize: '13px'

          colorsRow = (colors_ids) =>
            for i in colors_ids
              colors = @props.colors[i]
              rgbs =
                if colors?
                  colors["tag_#{j}"] for j in [1..5]
                else
                  []
              child 'label', key: "colors-#{i}", =>
                props style: display: 'table-cell'
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
                child 'div', style:
                  width: 90
                  height: 35
                  marginLeft: 10
                  backgroundImage: gradient
                  display: 'inline-block'
          child 'div.newStep2ColorRow', => colorsRow [1, 2, 3]
          child 'div.newStep2ColorRow', => colorsRow [4, 5, 6]

        child 'div', =>
          props style: paddingTop: 20
          child 'div.newStep2LeftCol', =>
            child 'form', =>
              child 'h3', => raw 'CATEGORIES'
              for tag, i in @props.tag_string.split(',')
                tag = tag.replace(/^\s+/, '')
                do (i) =>
                  child 'div', key: "tag-#{i}", =>
                    props style:
                      display: 'table'
                      width: '100%'
                      marginTop: 30
                      marginBottom: 30
                    child 'div', =>
                      props style:
                        display: 'table-cell'
                        width: 30
                      child 'div', style:
                        width: 30
                        height: 30
                        borderRadius: 15
                        backgroundColor: @props.colors[@props.game.colors_id]["tag_#{(i % 8) + 1}"] or 'black'
                        marginTop: 'auto'
                        marginBottom: 'auto'
                    child 'div', =>
                      props style:
                        display: 'table-cell'
                        position: 'relative'
                      child 'input',
                        type: 'text'
                        value: tag
                        onChange: @handleChange
                        ref: (elt) => @tag_boxes.push(elt) unless elt is null
                        style:
                          position: 'absolute'
                          width: 'calc(100% - 40px)'
                          boxSizing: 'border-box'
                          marginLeft: 20
                          top: 0
                    child 'div', =>
                      props
                        style:
                          display: 'table-cell'
                          width: 30
                          color: 'rgb(255,87,61)'
                          fontSize: '25px'
                          cursor: 'pointer'
                          position: 'relative'
                        onClick: => @deleteTag i
                      child 'span', style: {position: 'absolute', top: -3}, => raw '×'
              child 'p', =>
                props style: marginTop: 40
                child 'span', =>
                  props
                    style:
                      backgroundColor: 'rgb(97,201,226)'
                      color: 'white'
                      paddingLeft: 25
                      paddingRight: 25
                      paddingTop: 10
                      paddingBottom: 10
                      cursor: 'pointer'
                    onClick: @addTag
                  raw 'ADD CATEGORY'
          child 'div.newStep2RightCol', =>
            child 'div.newStep2MapContainer', style: {width: '100%', position: 'relative'}, =>
              child GoogleMap,
                ref: 'map'
                center: [@props.game.latitude, @props.game.longitude]
                zoom: Math.max(2, @props.game.zoom)
                options: minZoom: 2
                onChange: @handleMapChange
              child 'h3', =>
                props style:
                  position: 'absolute'
                  top: 20
                  left: 20
                  padding: 0
                  margin: 0
                raw 'POSITION MAP CENTER'
          child 'div', style: clear: 'both'
        child 'p', =>
          child 'a', href: '#', =>
            child 'span', =>
              props style:
                float: 'right'
                color: 'white'
                backgroundColor: 'lightgray'
                paddingLeft: 35
                paddingRight: 35
                paddingTop: 8
                paddingBottom: 8
              raw 'CANCEL'

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

  handleMapChange: ({center: {lat, lng}, zoom}) ->
    game = update @props.game,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
    @props.onChange game, @props.tag_string

NewStep3 = React.createClass
  displayName: 'NewStep3'

  render: ->
    make 'div', =>
      child 'div', =>
        props
          style:
            width: '100%'
            textAlign: 'center'
            backgroundColor: 'gray'
            color: 'white'
            paddingTop: 60
            paddingBottom: 60
            position: 'relative'
            backgroundImage: 'url(../assets/photos/siftr-header.jpg)'
            backgroundSize: 'cover'
            backgroundRepeat: 'no-repeat'
        child 'span', style: {fontSize: '30px'}, => raw 'NEW SIFTR'
        child 'a', href: '#new2', =>
          child 'div.newPrevButton', =>
            raw '< BACK, APPEARANCE'
        child 'div.newNextButton', =>
          props
            style:
              backgroundColor: 'rgb(254,212,0)'
            onClick: @props.onCreate
          raw 'PUBLISH!'

      child 'div.newStep3', =>
        child 'h2', style: {textAlign: 'center'}, => raw 'SETTINGS'
        child 'h4', => raw 'PRIVACY'
        child 'p', =>
          raw 'Do you want '
          child 'b', => raw @props.game.name
          raw ' to be public or private?'
        button = (str, checked, check) =>
          child 'span', =>
            props
              style:
                boxSizing: 'border-box'
                width: 120
                padding: 10
                display: 'inline-block'
                textAlign: 'center'
                border: '3px solid rgb(51,191,224)'
                cursor: 'pointer'
                # TODO: ask Eric if the below colors are right, or if they should be flipped
                color: if checked then 'white' else 'rgb(51,191,224)'
                backgroundColor: if checked then 'rgb(51,191,224)' else 'white'
              onClick: check
            raw str
        child 'p', =>
          props style:
            marginTop: 30
            marginBottom: 30
          button 'PUBLIC', @props.game.published, =>
            @props.onChange update @props.game, published: $set: true
          button 'PRIVATE', not @props.game.published, =>
            @props.onChange update @props.game, published: $set: false
        child 'h4', => raw 'MODERATION'
        child 'p', =>
          raw 'Do new user submissions have to be approved by you before they are added to '
          child 'b', => raw @props.game.name
          raw '?'
        child 'p', =>
          props style:
            marginTop: 30
            marginBottom: 30
          button 'YES', @props.game.moderated, =>
            @props.onChange update @props.game, moderated: $set: true
          button 'NO', not @props.game.moderated, =>
            @props.onChange update @props.game, moderated: $set: false
        child 'h4', => raw 'URL'
        child 'p', =>
          child 'input',
            type: 'text'
            placeholder: 'URL (optional)'
            value: @props.game.siftr_url
            onChange: (e) => @props.onChange update @props.game, siftr_url: $set: e.target.value
            style: width: '100%'
        child 'p', =>
          if @props.game.siftr_url
            child 'b', => raw @props.game.name
            raw " will be located at "
            child 'code', => raw "#{SIFTR_URL}#{@props.game.siftr_url}"
          else
            raw "Enter a custom identifier for your Siftr's web address."

document.addEventListener 'DOMContentLoaded', (event) ->
  ReactDOM.render make(App, aris: new Aris), document.getElementById('the-container')
