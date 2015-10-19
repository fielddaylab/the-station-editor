React = require 'react/addons'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v

renderMarkdown = (str) ->
  __html: markdown.toHTML str

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
    new_step: null

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
        edit_game: new Game
    else if hash is 'new2'
      if @state.new_step is null
        window.location.replace '#'
      else
        @setState
          screen: 'new2'
          new_step: 2
    else if hash is 'new3'
      if @state.new_step is null
        window.location.replace '#'
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

  handleSave: ->
    @props.aris.updateGame @state.edit_game
    , (result) =>
      window.location.hash = '#'
      if result.returnCode is 0 and result.data?
        newGame = result.data
        @setState (previousState, currentProps) =>
          React.addons.update previousState,
            games:
              $apply: (games) =>
                for game in games
                  if game.game_id is newGame.game_id
                    newGame
                  else
                    game

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
                  <NewStep1
                    game={@state.edit_game}
                    tags={@state.new_tags}
                    onChange={(game) => @setState edit_game: game} />
                when 'new2'
                  <NewStep2
                    game={@state.edit_game}
                    tags={@state.new_tags}
                    onChange={(game) => @setState edit_game: game} />
                when 'new3'
                  <NewStep3
                    game={@state.edit_game}
                    tags={@state.new_tags}
                    onChange={(game) => @setState edit_game: game} />
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
              <button type="button" onClick={=> @login @state.username, @state.password}>Login</button>
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
      <div dangerouslySetInnerHTML={renderMarkdown @props.game.description} />
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
        <input type="text" />
      </label>
      <label>
        <p>Tags, separated by comma</p>
        <input type="text" />
      </label>
      <label>
        <p>Description</p>
        <textarea />
      </label>
      <label>
        <p>Siftr Icon</p>
        <p><b>TODO</b></p>
      </label>
      <p><a href="#">Cancel</a></p>
    </div>

NewStep2 = React.createClass
  render: ->
    <div>
      <h2>New Siftr 2</h2>
      <p>
        <a href="#new1">Back, setup</a>
      </p>
      <p>
        <a href="#new3">Next, settings</a>
      </p>
      <p><a href="#">Cancel</a></p>
    </div>

NewStep3 = React.createClass
  render: ->
    <div>
      <h2>New Siftr 3</h2>
      <p>
        <a href="#new2">Back, setup</a>
      </p>
      <p>
        <button type="button" onClick={@handleCreate}>Create!</button>
      </p>
      <p><a href="#">Cancel</a></p>
    </div>

document.addEventListener 'DOMContentLoaded', (event) ->
  React.render <App aris={new Aris} />, document.body
