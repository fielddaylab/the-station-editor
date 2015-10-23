React = require 'react/addons'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v

renderMarkdown = (str) ->
  __html: markdown.toHTML(str ? '')

countContributors = (notes) ->
  user_ids = {}
  for note in notes
    user_ids[note.user.user_id] = true
    for comment in note.comments
      user_ids[comment.user.user_id] = true
  Object.keys(user_ids).length

App = React.createClass
  getInitialState: ->
    auth: null
    games: []
    tags: {}
    notes: {}
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
            React.addons.update previousState,
              notes:
                $merge: do =>
                  obj = {}
                  obj[game.game_id] = result.data
                  obj

  updateTags: (games) ->
    games.forEach (game) =>
      @props.aris.getTagsForGame
        game_id: game.game_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState (previousState, currentProps) =>
            React.addons.update previousState,
              tags:
                $merge: do =>
                  obj = {}
                  obj[game.game_id] = result.data
                  obj

  # Adds the game to the known games list,
  # or updates an existing game if it shares the game ID.
  updateStateGame: (newGame) ->
    @setState (previousState, currentProps) =>
      React.addons.update previousState,
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
        @createNewIcon newGame, ({data: media}) =>
          @props.aris.call 'games.updateGame',
            game_id: newGame.game_id
            icon_media_id: media.media_id
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
          React.addons.update previousState,
            notes:
              $merge: do =>
                obj = {}
                obj[newGame.game_id] = []
                obj
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
    <div>
      <div id="the-nav-bar">
        <div id="the-logo">Siftr</div>
        <div id="the-discover-button">Discover</div>
        <div id="the-my-account-button">My Account</div>
        <div id="the-my-siftrs-button">My Siftrs</div>
      </div>
      { if @state.auth?
          <form>
            <p><code>{ JSON.stringify @state.auth }</code></p>
            <button type="button" onClick={@logout}>Logout</button>
            {
              switch @state.screen
                when 'edit'
                  <EditSiftr
                    game={@state.edit_game}
                    onChange={(game) => @setState edit_game: game}
                    onSave={@handleSave} />
                when 'main'
                  <div>
                    <SiftrList
                      games={@state.games}
                      notes={@state.notes}
                      tags={@state.tags} />
                    <p>
                      <a href="#new1">
                        New Siftr
                      </a>
                    </p>
                  </div>
                when 'new1'
                  f = (game, tag_string) => @setState
                    new_game: game
                    new_tag_string: tag_string
                  <NewStep1
                    game={@state.new_game}
                    tag_string={@state.new_tag_string}
                    icon={@state.new_icon}
                    onChange={(new_game, new_tag_string) => @setState {new_game, new_tag_string}}
                    onIconChange={(new_icon) => @setState {new_icon}} />
                when 'new2'
                  <NewStep2
                    game={@state.new_game}
                    tag_string={@state.new_tag_string}
                    onChange={(new_game, new_tag_string) => @setState {new_game, new_tag_string}} />
                when 'new3'
                  <NewStep3
                    game={@state.new_game}
                    onChange={(new_game) => @setState {new_game}}
                    onCreate={@createGame} />
            }
          </form>
        else
          <form>
            <p>
              <input type="text" placeholder="Username" value={@state.username} onChange={(e) => @setState username: e.target.value} />
            </p>
            <p>
              <input type="password" placeholder="Password" value={@state.password} onChange={(e) => @setState password: e.target.value} />
            </p>
            <p>
              <button type="submit" onClick={(e) => e.preventDefault(); @login(@state.username, @state.password)}>Login</button>
            </p>
          </form>
      }
    </div>

SiftrList = React.createClass
  render: ->
    <ul>
      { for game in @props.games
          do (game) =>
            notes = @props.notes[game.game_id]
            <li key={"game-#{game.game_id}"}>
              <p>
                { game.name }
                {' '} <a href={"#{SIFTR_URL}#{game.siftr_url or game.game_id}"}>[View]</a>
                {' '} <a href={"\#edit#{game.game_id}"}>[Edit]</a>
              </p>
              <p>
                { notes?.length ? '...' } items
                {' | '} { if notes? then countContributors(notes) else '...' } contributors
                {' | '} { if game.published then 'Public' else 'Private' }
                {' | '} { if game.moderated then 'Moderated' else 'Non-Moderated' }
              </p>
            </li>
      }
    </ul>

EditSiftr = React.createClass
  render: ->
    <form>
      <p>
        <label>
          Name <br />
          <input ref="name" type="text" value={@props.game.name} onChange={@handleChange} />
        </label>
      </p>
      <p>
        <label>
          Description <br />
          <textarea ref="description" value={@props.game.description} onChange={@handleChange} />
        </label>
      </p>
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} style={border: '1px solid black'} />
      <p>
        <label>
          URL <br />
          <input ref="siftr_url" type="text" value={@props.game.siftr_url} onChange={@handleChange} />
        </label>
      </p>
      <p>
        Your Siftr's URL will be <code>{"#{SIFTR_URL}#{@props.game.siftr_url or @props.game.game_id}"}</code>
      </p>
      <p>
        <label>
          <input ref="published" type="checkbox" checked={@props.game.published} onChange={@handleChange} />
          Published
        </label>
      </p>
      <p>
        <label>
          <input ref="moderated" type="checkbox" checked={@props.game.moderated} onChange={@handleChange} />
          Moderated
        </label>
      </p>
      <div style={width: '500px', height: '500px'}>
        <GoogleMap
          ref="map"
          center={[@props.game.latitude, @props.game.longitude]}
          zoom={@props.game.zoom}
          options={minZoom: 1}
          onBoundsChange={@handleMapChange}>
        </GoogleMap>
      </div>
      <p>
        <button type="button" onClick={@props.onSave}>Save changes</button>
      </p>
      <p><a href="#">Back to Siftr list</a></p>
    </form>

  handleChange: ->
    game = React.addons.update @props.game,
      name:
        $set: @refs['name'].getDOMNode().value
      description:
        $set: @refs['description'].getDOMNode().value
      siftr_url:
        $set: @refs['siftr_url'].getDOMNode().value or null
      published:
        $set: @refs['published'].getDOMNode().checked
      moderated:
        $set: @refs['moderated'].getDOMNode().checked
    @props.onChange game

  handleMapChange: ([lat, lng], zoom, bounds, marginBounds) ->
    game = React.addons.update @props.game,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
    @props.onChange game

NewStep1 = React.createClass
  render: ->
    <div>
      <h2>New Siftr</h2>
      <p>
        <a href="#new2">Next, appearance</a>
      </p>
      <p>What kind of Siftr do you want to make?</p>
      <label>
        <p>Name</p>
        <input ref="name" type="text" value={@props.game.name} onChange={@handleChange} />
      </label>
      <label>
        <p>Tags, separated by comma</p>
        <input ref="tag_string" type="text" value={@props.tag_string} onChange={@handleChange} />
      </label>
      <label>
        <p>Description</p>
        <textarea ref="description" value={@props.game.description} onChange={@handleChange} />
      </label>
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} style={border: '1px solid black'} />
      <label>
        <p>Siftr Icon</p>
        { if @props.icon?
            <p><img src={@props.icon} /></p>
          else
            ''
        }
        <p><button type="button" onClick={@selectImage}>Select Image</button></p>
      </label>
      <p><a href="#">Cancel</a></p>
    </div>

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
    game = React.addons.update @props.game,
      name:
        $set: @refs.name.getDOMNode().value
      description:
        $set: @refs.description.getDOMNode().value
    tag_string = @refs.tag_string.getDOMNode().value
    @props.onChange(game, tag_string)

NewStep2 = React.createClass
  render: ->
    @tag_boxes = []
    <div>
      <h2>New Siftr 2</h2>
      <p>
        <a href="#new1">Back, setup</a>
      </p>
      <p>
        <a href="#new3">Next, settings</a>
      </p>
      <form>
        <p><label><input ref="colors_1" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 1} /> Primary</label></p>
        <p><label><input ref="colors_2" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 2} /> Sunset</label></p>
        <p><label><input ref="colors_3" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 3} /> Willy St.</label></p>
        <p><label><input ref="colors_4" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 4} /> Nature</label></p>
        <p><label><input ref="colors_5" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 5} /> Monochromatic Blue</label></p>
        <p><label><input ref="colors_6" type="radio" onChange={@handleChange} name="colors" checked={@props.game.colors_id is 6} /> Monochromatic Red</label></p>
      </form>
      <form>
        <p><b>TAGS</b></p>
        <ul>
          { for tag, i in @props.tag_string.split(',')
              tag = tag.replace(/^\s+/, '')
              continue if tag is ''
              <li key={"tag-#{i}"}>
                <input type="text" value={tag} onChange={@handleChange} ref={(elt) => @tag_boxes.push(elt) unless elt is null} />
              </li>
          }
        </ul>
      </form>
      <p>Position Map Center</p>
      <div style={width: '500px', height: '500px'}>
        <GoogleMap
          ref="map"
          center={[@props.game.latitude, @props.game.longitude]}
          zoom={@props.game.zoom}
          options={minZoom: 1}
          onBoundsChange={@handleMapChange}>
        </GoogleMap>
      </div>
      <p><a href="#">Cancel</a></p>
    </div>

  handleChange: ->
    colors_id = 1
    for i in [1..6]
      if @refs["colors_#{i}"].getDOMNode().checked
        colors_id = i
    game = React.addons.update @props.game,
      colors_id:
        $set: colors_id
    tag_string = @tag_boxes.map((input) => input.getDOMNode().value).join(',')
    @props.onChange game, tag_string

  handleMapChange: ([lat, lng], zoom, bounds, marginBounds) ->
    game = React.addons.update @props.game,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
    @props.onChange game, @props.tag_string

NewStep3 = React.createClass
  render: ->
    <div>
      <h2>New Siftr 3</h2>
      <p>
        <a href="#new2">Back, setup</a>
      </p>
      <p>
        <button type="button" onClick={@props.onCreate}>Create!</button>
      </p>
      <form>
        <p>
          <label>
            <input ref="published" type="checkbox" checked={@props.game.published} onChange={@handleChange} />
            Public
          </label>
        </p>
        <p>
          <label>
            <input ref="moderated" type="checkbox" checked={@props.game.moderated} onChange={@handleChange} />
            Moderation
          </label>
        </p>
      </form>
      <p><a href="#">Cancel</a></p>
    </div>

  handleChange: ->
    game = React.addons.update @props.game,
      published:
        $set: @refs.published.getDOMNode().checked
      moderated:
        $set: @refs.moderated.getDOMNode().checked
    @props.onChange game

document.addEventListener 'DOMContentLoaded', (event) ->
  React.render <App aris={new Aris} />, document.body
