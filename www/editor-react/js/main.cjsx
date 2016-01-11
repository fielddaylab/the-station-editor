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

  componentDidMount: ->
    @login undefined, undefined
    @applyHash()
    window.addEventListener 'hashchange', => @applyHash()
    @getColors()

  applyHash: ->
    hash = window.location.hash[1..]
    if hash[0..3] is 'edit'
      game_id = parseInt hash[4..]
      matchingGames =
        game for game in @state.games when game.game_id is game_id
      if matchingGames.length is 1
        @setState
          screen: 'edit'
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
    else
      @setState screen: 'main'

  login: (username, password) ->
    @props.aris.login username, password, => @updateLogin()

  logout: ->
    window.location.hash = '#'
    @props.aris.logout()
    @updateLogin()

  updateLogin: ->
    @setState auth: @props.aris.auth
    @updateGames()

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
        game_id: game.game_id
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

  render: ->
    make 'div', =>
      child 'div#the-nav-bar', =>
        child 'div#the-logo', => raw 'Siftr'
        child 'div#the-discover-button', => raw 'Discover'
        child 'div#the-my-account-button', => raw 'My Account'
        child 'div#the-my-siftrs-button', => raw 'My Siftrs'
      if @state.auth?
        child 'div', =>
          child 'p', => child 'code', => raw JSON.stringify @state.auth
          child 'button', type: 'button', onClick: @logout, => raw 'Logout'
          switch @state.screen
            when 'edit'
              child EditSiftr,
                game: @state.edit_game
                colors: @state.colors
                onChange: (game) => @setState edit_game: game
                onSave: @handleSave
            when 'main'
              child 'div', =>
                child SiftrList,
                  games: @state.games
                  colors: @state.colors
                  notes: @state.notes
                  tags: @state.tags
                child 'p', => child 'a', href: '#new1', => raw 'New Siftr'
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
        child 'form', =>
          child 'p', =>
            child 'input', type: 'text', placeholder: 'Username', value: @state.username, onChange: (e) => @setState username: e.target.value
          child 'p', =>
            child 'input', type: 'password', placeholder: 'Password', value: @state.password, onChange: (e) => @setState password: e.target.value
          child 'p', =>
            child 'button',
              type: 'submit'
              onClick: (e) =>
                e.preventDefault()
                @login @state.username, @state.password
            , => raw 'Login'

SiftrList = React.createClass
  displayName: 'SiftrList'

  render: ->
    make 'ul', =>
      @props.games.forEach (game) =>
        notes = @props.notes[game.game_id]
        child 'li', key: "game-#{game.game_id}", =>
          child 'p', =>
            raw game.name
            raw ' '
            child 'a', href: "#{SIFTR_URL}#{game.siftr_url or game.game_id}", => raw '[View]'
            raw ' '
            child 'a', href: "\#edit#{game.game_id}", => raw '[Edit]'
          child 'p', =>
            raw "#{notes?.length ? '...'} items"
            raw ' | '
            raw "#{if notes? then countContributors(notes) else '...'} contributors"
            raw ' | '
            raw (if game.published then 'Public' else 'Private')
            raw ' | '
            raw (if game.moderated then 'Moderated' else 'Non-Moderated')
          if (colors = @props.colors[game.colors_id])?
            rgbs =
              colors["tag_#{i}"] for i in [1..5]
            child 'div', style:
              backgroundImage: "linear-gradient(to right, #{rgbs.join(', ')})"
              height: '20px'
              width: '100%'

EditSiftr = React.createClass
  displayName: 'EditSiftr'

  render: ->
    make 'form', =>
      child 'p', =>
        child 'label', =>
          raw 'Name'
          child 'br'
          child 'input', ref: 'name', type: 'text', value: @props.game.name, onChange: @handleChange
      child 'p', =>
        child 'label', =>
          raw 'Description'
          child 'br'
          child 'textarea', ref: 'description', value: @props.game.description, onChange: @handleChange
      child 'div',
        dangerouslySetInnerHTML: renderMarkdown @props.game.description
        style: border: '1px solid black'
      child 'p', =>
        child 'label', =>
          raw 'URL'
          child 'br'
          child 'input', ref: 'siftr_url', type: 'text', value: @props.game.siftr_url, onChange: @handleChange
      child 'p', =>
        raw "Your Siftr's URL will be "
        child 'code', => raw "#{SIFTR_URL}#{@props.game.siftr_url or @props.game.game_id}"
      child 'p', =>
        child 'label', =>
          child 'input', ref: 'published', type: 'checkbox', checked: @props.game.published, onChange: @handleChange
          raw 'Published'
      child 'p', =>
        child 'label', =>
          child 'input', ref: 'moderated', type: 'checkbox', checked: @props.game.moderated, onChange: @handleChange
          raw 'Moderated'
      for i in [1..6]
        colors = @props.colors[i]
        rgbs =
          if colors?
            colors["tag_#{j}"] for j in [1..5]
          else
            []
        child 'label', key: "colors-#{i}", =>
          child 'p', =>
            child 'input', ref: "colors_#{i}", type: 'radio', onChange: @handleChange, name: 'colors', checked: @props.game.colors_id is i
            raw colors?.name
          child 'div', style:
            backgroundImage: "linear-gradient(to right, #{rgbs.join(', ')})"
            height: '20px'
            width: '100%'
      child 'div', style: {width: '500px', height: '500px'}, =>
        child GoogleMap,
          ref: 'map'
          center: [@props.game.latitude, @props.game.longitude]
          zoom: Math.max(2, @props.game.zoom)
          options: minZoom: 2
          onChange: @handleMapChange
      child 'p', =>
        child 'button', type: 'button', onClick: @props.onSave, =>
          raw 'Save changes'
      child 'p', => child 'a', href: '#', => raw 'Back to Siftr list'

  handleChange: ->
    game = update @props.game,
      name:
        $set: @refs['name'].value
      description:
        $set: @refs['description'].value
      siftr_url:
        $set: @refs['siftr_url'].value or null
      published:
        $set: @refs['published'].checked
      moderated:
        $set: @refs['moderated'].checked
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
      child 'h2', => raw 'New Siftr'
      child 'p', =>
        child 'a', href: '#new2', => raw 'Next, appearance'
      child 'label', =>
        child 'p', => raw 'Name'
        child 'input', ref: 'name', type: 'text', value: @props.game.name, onChange: @handleChange
      child 'label', =>
        child 'p', => raw 'Tags, separated by comma'
        child 'input', ref: 'tag_string', type: 'text', value: @props.tag_string, onChange: @handleChange
      child 'label', =>
        child 'p', => raw 'Description'
        child 'textarea', ref: 'description', value: @props.game.description, onChange: @handleChange
      child 'div', =>
        dangerouslySetInnerHTML: renderMarkdown @props.game.description
        style: border: '1px solid black'
      child 'label', =>
        child 'p', => raw 'Siftr Icon'
        if @props.icon?
          raw 'div', style:
            backgroundImage: "url(#{@props.icon})"
            backgroundSize: 'contain'
            backgroundRepeat: 'no-repeat'
            backgroundPosition: 'center'
            width: '100px'
            height: '100px'
        child 'p', =>
          child 'button', type: 'button', onClick: @selectImage, =>
            raw 'Select Image'
      child 'p', => child 'a', href: '#', => raw 'Cancel'

  selectImage: ->
    input = document.createElement 'input'
    input.type = 'file'
    input.onchange = (e) =>
      file = e.target.files[0]
      fr = new FileReader
      fr.onload = =>
        @props.onIconChange fr.result
      fr.readAsDataURL file
    input.click()

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
    @tag_boxes = []
    make 'div', =>
      child 'h2', => raw 'New Siftr 2'
      child 'p', => child 'a', href: '#new1', => raw 'Back, setup'
      child 'p', => child 'a', href: '#new3', => raw 'Next, settings'
      child 'form', =>
        for i in [1..6]
          colors = @props.colors[i]
          rgbs =
            if colors?
              colors["tag_#{j}"] for j in [1..5]
            else
              []
          child 'label', key: "colors-#{i}", =>
            child 'p', =>
              child 'input', ref: "colors_#{i}", type: 'radio', onChange: @handleChange, name: 'colors', checked: @props.game.colors_id is i
              raw colors?.name
            child 'div', style:
              backgroundImage: "linear-gradient(to right, #{rgbs.join(', ')})"
              height: '20px'
              width: '100%'
      child 'form', =>
        child 'p', => child 'b', => raw 'TAGS'
        child 'ul', =>
          for tag, i in @props.tag_string.split(',')
            do (i) =>
              tag = tag.replace(/^\s+/, '')
              child 'li', key: "tag-#{i}", =>
                child 'input', type: 'text', value: tag, onChange: @handleChange, ref: (elt) => @tag_boxes.push(elt) unless elt is null
                child 'button', type: 'button', onClick: (=> @deleteTag i), => raw 'Delete'
          child 'li', =>
            child 'button', type: 'button', onClick: @addTag, => raw 'Add Tag'
      child 'p', => raw 'Position Map Center'
      child 'div', style: {width: '500px', height: '500px'}, =>
        child GoogleMap,
          ref: 'map'
          center: [@props.game.latitude, @props.game.longitude]
          zoom: Math.max(2, @props.game.zoom)
          options: minZoom: 2
          onChange: @handleMapChange
      child 'p', => child 'a', href: '#', => raw 'Cancel'

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
      child 'h2', => raw 'New Siftr 3'
      child 'p', =>
        child 'a', href: '#new2', => raw 'Back, setup'
      child 'p', =>
        child 'button', =>
          props
            type: 'button'
            onClick: @props.onCreate
          raw 'Create!'
      child 'form', =>
        child 'p', =>
          child 'label', =>
            child 'input', => props ref: 'published', type: 'checkbox', checked: @props.game.published, onChange: @handleChange
            raw 'Public'
        child 'p', =>
          child 'label', =>
            child 'input', => props ref: 'moderated', type: 'checkbox', checked: @props.game.moderated, onChange: @handleChange
            raw 'Moderation'
      child 'p', => child 'a', href: '#', => raw 'Cancel'

  handleChange: ->
    game = update @props.game,
      published:
        $set: @refs.published.checked
      moderated:
        $set: @refs.moderated.checked
    @props.onChange game

document.addEventListener 'DOMContentLoaded', (event) ->
  ReactDOM.render <App aris={new Aris} />, document.getElementById('the-container')
