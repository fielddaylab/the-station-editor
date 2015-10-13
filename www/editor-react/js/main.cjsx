React = require 'react/addons'
GoogleMap = require 'google-map-react'
{markdown} = require 'markdown'
for k, v of require '../../shared/aris.js'
  window[k] = v
{Router, Route, Link} = require 'react-router'

countContributors = (notes) ->
  user_ids = {}
  for note in notes
    user_ids[note.user.user_id] = true
    for comment in note.comments
      user_ids[comment.user.user_id] = true
  Object.keys(user_ids).length

SiftrList = React.createClass
  render: ->
    <ul>
      { for game in @props.games
          notes = @props.notes[game.game_id]
          <li key={"game-#{game.game_id}"}>
            <p>
              {' '} { game.name }:
              {' '} { notes?.length ? '...' } notes,
              {' '} { if notes? then countContributors(notes) else '...' } contributors
            </p>
            <p>
              <Link to={"/edit/#{game.game_id}"}>Edit Siftr</Link>
            </p>
            <p>
              <a href="#{SIFTR_URL}/#{game.siftr_url or game.game_id}">Go to Siftr</a>
            </p>
          </li>
      }
    </ul>

App = React.createClass
  getInitialState: ->
    auth: null
    games: []
    tags: {}
    notes: {}
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
        {
          if @props.children?
            React.cloneElement @props.children,
              games: @state.games
              notes: @state.notes
              tags: @state.tags
          else
            <SiftrList
              games={@state.games}
              notes={@state.notes}
              tags={@state.tags}
              />
        }
      </form>
    else
      <form>
        <input type="text" value={@state.username} onChange={(e) => @setState username: e.target.value} />
        <input type="password" value={@state.password} onChange={(e) => @setState password: e.target.value} />
        <button type="button" onClick={=> @login @state.username, @state.password}>Login</button>
      </form>

EditSiftr = React.createClass
  render: ->
    game_id = @props.params.gameID
    tags = @props.tags[game_id] ? []
    <div>
      <p>Tags</p>
      <ul>
        { for tag in tags
            <li key={"tag-#{tag.tag_id}"}>{ tag.tag }</li>
        }
      </ul>
      <p>
        <Link to="/">
          Back to Siftrs
        </Link>
      </p>
    </div>

# Wrap a React class to have some new default prop values.
prefillProps = (klass, props) ->
  React.createClass
    getDefaultProps: ->
      props
    render: ->
      <klass {...@props} />

document.addEventListener 'DOMContentLoaded', (event) ->
  app =
    <Router>
      <Route path="/" component={prefillProps App, aris: new Aris}>
        <Route path="edit/:gameID" component={EditSiftr} />
      </Route>
    </Router>
  React.render app, document.getElementById('output')
