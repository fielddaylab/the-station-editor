React = require 'react/addons'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v

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
    username: ''
    password: ''

  componentDidMount: ->
    @login undefined, undefined

  login: (username, password) ->
    @props.aris.login username, password, => @updateLogin()

  logout: ->
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

  render: ->
    if @state.auth?
      <form>
        <p><code>{ JSON.stringify @state.auth }</code></p>
        <button type="button" onClick={@logout}>Logout</button>
        <ul>
          { for game in @state.games
              <li key={"game-#{game.game_id}"}>
                <p><code>{ JSON.stringify game }</code></p>
                <p>
                  <a href="#{SIFTR_URL}/#{game.siftr_url or game.game_id}">Go to Siftr</a>
                </p>
                <p>{ (@state.notes[game.game_id] ? []).length } notes</p>
                <p>{ countContributors(@state.notes[game.game_id] ? []) } contributors</p>
                <ul>
                  { for tag in @state.tags[game.game_id] ? []
                      <li key={"tag-#{tag.tag_id}"}><code>{ JSON.stringify tag }</code></li>
                  }
                </ul>
              </li>
          }
        </ul>
      </form>
    else
      <form>
        <input type="text" value={@state.username} onChange={(e) => @setState username: e.target.value} />
        <input type="password" value={@state.password} onChange={(e) => @setState password: e.target.value} />
        <button type="button" onClick={=> @login @state.username, @state.password}>Login</button>
      </form>

document.addEventListener 'DOMContentLoaded', (event) ->
  React.render <App aris={new Aris} />, document.getElementById('output')
