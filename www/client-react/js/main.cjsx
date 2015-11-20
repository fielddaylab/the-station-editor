React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
{markdown} = require 'markdown'
{Game, Colors, User, Tag, Comment, Note, Aris} = require '../../shared/aris.js'
GoogleMap = require 'google-map-react'

T = React.PropTypes

renderMarkdown = (str) ->
  __html: markdown.toHTML str

# This is Haskell right? It uses indentation and everything
match = (val, branches, def = (-> throw 'Match failed')) ->
  for k, v of branches
    if k of val
      return v val[k]
  def()

App = React.createClass
  displayName: 'App'

  propTypes:
    game: T.instanceOf Game
    aris: T.instanceOf Aris

  getInitialState: ->
    notes: []
    map_notes: []
    map_clusters: []
    latitude: @props.game.latitude
    longitude: @props.game.longitude
    zoom: @props.game.zoom
    min_latitude: null
    max_latitude: null
    min_longitude: null
    max_longitude: null

  handleMapChange: ({center: {lat, lng}, zoom, bounds: {nw, se}}) ->
    map_params =
      latitude: lat
      longitude: lng
      zoom: zoom
      min_latitude: se.lat
      max_latitude: nw.lat
      min_longitude: nw.lng
      max_longitude: se.lng
    @setState map_params
    @search map_params

  search: (map_params = @state) ->
    @props.aris.call 'notes.siftrSearch',
      game_id: @props.game.game_id
      min_latitude: map_params.min_latitude
      max_latitude: map_params.max_latitude
      min_longitude: map_params.min_longitude
      max_longitude: map_params.max_longitude
      zoom: @state.zoom
    , ({data, returnCode}) =>
      @setState
        notes:        data.notes
        map_notes:    data.map_notes
        map_clusters: data.map_clusters

  render: ->
    <div>
      <div style={position: 'fixed', top: 0, left: 0, width: '100%', height: '100%'}>
        <GoogleMap
          center={[@state.latitude, @state.longitude]}
          zoom={Math.max 2, @state.zoom}
          options={minZoom: 2}
          onChange={@handleMapChange}>
          { for note in @state.map_notes
              <div key={note.note_id}
                lat={note.latitude}
                lng={note.longitude}
                style={marginLeft: '-5px', marginTop: '-5px', width: '10px', height: '10px', backgroundColor: 'magenta', cursor: 'pointer'}
                />
          }
          { for cluster, i in @state.map_clusters
              lat = cluster.min_latitude + (cluster.max_latitude - cluster.min_latitude) / 2
              lng = cluster.min_longitude + (cluster.max_longitude - cluster.min_longitude) / 2
              if -180 < lng < 180 && -90 < lat < 90
                <div key={"#{lat}-#{lng}"}
                  lat={lat}
                  lng={lng}
                  style={marginLeft: '-10px', marginTop: '-10px', width: '20px', height: '20px', backgroundColor: 'green', color: 'white', cursor: 'pointer'}>
                  { cluster.note_count }
                </div>
              else
                continue
          }
        </GoogleMap>
      </div>
    </div>

document.addEventListener 'DOMContentLoaded', ->

  siftr_url = window.location.search.replace('?', '')
  if siftr_url.length is 0
    siftr_url = window.location.pathname.replace(/\//g, '')
  unless siftr_url.match(/[^0-9]/)
    siftr_id = parseInt siftr_url
    siftr_url = null

  aris = new Aris
  continueWithGame = (game) ->
    aris.getTagsForGame
      game_id: game.game_id
    , ({data: tags, returnCode}) =>
      if returnCode is 0 and tags?
        game.tags = tags

        aris.getUsersForGame
          game_id: game.game_id
        , ({data: owners, returnCode}) =>
          if returnCode is 0 and owners?
            game.owners = owners

            ReactDOM.render <App game={game} aris={aris} />, document.getElementById('the-container')

  if siftr_id?
    aris.getGame
      game_id: siftr_id
    , ({data: game, returnCode}) ->
      if returnCode is 0 and game?
        continueWithGame game
  else if siftr_url?
    aris.searchSiftrs
      siftr_url: siftr_url
    , ({data: games, returnCode}) ->
      if returnCode is 0 and games.length is 1
        continueWithGame games[0]
