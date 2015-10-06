React = require 'react/addons'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v

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
            games: result.data
            tags: {}
          @updateTags result.data
        else
          @setState games: []
    else
      @setState games: []

  updateTags: (games) ->
    games.forEach (game) =>
      @props.aris.getTagsForGame
        game_id: game.game_id
      , (result) =>
        if result.returnCode is 0 and result.data?
          @setState (previousState, currentProps) ->
            obj = {}
            obj[game.game_id] = result.data
            React.addons.update previousState,
              tags:
                $merge: obj

  render: ->
    if @state.auth?
      <form>
        <p>{ JSON.stringify @state.auth }</p>
        <button type="button" onClick={@logout}>Logout</button>
        <ul>
          { for game in @state.games
              <li key={"game-#{game.game_id}"}>
                <p>{ JSON.stringify game }</p>
                <ul>
                  { for tag in @state.tags[game.game_id] ? []
                      <li key={"tag-#{tag.tag_id}"}>{ JSON.stringify tag }</li>
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
