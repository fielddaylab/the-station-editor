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
    page: 1
    latitude: @props.game.latitude
    longitude: @props.game.longitude
    zoom: @props.game.zoom
    min_latitude: null
    max_latitude: null
    min_longitude: null
    max_longitude: null
    search: ''
    mine: false
    order: 'recent'
    checked_tags: do =>
      o = {}
      for tag in @props.game.tags
        o[tag.tag_id] = false
      o

  handleMapChange: ({center: {lat, lng}, zoom, bounds: {nw, se}}) ->
    @search 0,
      latitude:
        $set: lat
      longitude:
        $set: lng
      zoom:
        $set: zoom
      min_latitude:
        $set: se.lat
      max_latitude:
        $set: nw.lat
      min_longitude:
        $set: nw.lng
      max_longitude:
        $set: se.lng

  search: (wait, updater) ->
    @setState (previousState) =>
      newState = update update(previousState, updater), page: {$set: 1}
      thisSearch = @lastSearch = Date.now()
      setTimeout =>
        return unless thisSearch is @lastSearch
        @props.aris.call 'notes.siftrSearch',
          game_id: @props.game.game_id
          min_latitude: newState.min_latitude
          max_latitude: newState.max_latitude
          min_longitude: newState.min_longitude
          max_longitude: newState.max_longitude
          zoom: newState.zoom
          limit: 50
          order: newState.order
          filter: if newState.mine then 'mine' else undefined
          tag_ids:
            tag_id for tag_id, checked of newState.checked_tags when checked
          search: newState.search
        , ({data, returnCode}) =>
          return unless thisSearch is @lastSearch
          if returnCode is 0 and data?
            @setState
              notes:        data.notes
              map_notes:    data.map_notes
              map_clusters: data.map_clusters
      , wait
      newState

  setPage: (page) ->
    thisSearch = @lastSearch = Date.now()
    @props.aris.call 'notes.siftrSearch',
      game_id: @props.game.game_id
      min_latitude: @state.min_latitude
      max_latitude: @state.max_latitude
      min_longitude: @state.min_longitude
      max_longitude: @state.max_longitude
      zoom: @state.zoom
      limit: 50
      offset: (page - 1) * 50
      order: @state.order
      filter: if @state.mine then 'mine' else undefined
      tag_ids:
        tag_id for tag_id, checked of @state.checked_tags when checked
      search: @state.search
      map_data: false
    , ({data, returnCode}) =>
      return unless thisSearch is @lastSearch
      if returnCode is 0 and data?
        @setState
          notes: data.notes
          page:  page

  render: ->
    <div>
      <div style={position: 'fixed', top: 0, left: 0, width: 'calc(100% - 300px)', height: '100%'}>
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
      <div style={position: 'fixed', top: 0, left: 'calc(100% - 300px)', width: '300px', height: '50%', overflowY: 'scroll'}>
        <p>
          <input type="text" value={@state.search} placeholder="Search..."
            onChange={(e) => @search 200,
              search:
                $set: e.target.value
            }
          />
        </p>
        <p>
          <label>
            <input type="radio" checked={@state.order is 'recent'}
              onClick={=> @search 0,
                order:
                  $set: 'recent'
              }
            />
            Recent
          </label>
        </p>
        <p>
          <label>
            <input type="radio" checked={@state.order is 'popular'}
              onClick={=> @search 0,
                order:
                  $set: 'popular'
              }
            />
            Popular
          </label>
        </p>
        <p>
          <label>
            <input type="checkbox" checked={@state.mine}
              onClick={=> @search 0,
                mine:
                  $apply: (x) => not x
              }
            />
            My Notes
          </label>
        </p>
        <p>
          <b>Tags</b>
        </p>
        { @props.game.tags.map (tag) =>
            <p key={tag.tag_id}>
              <label>
                <input type="checkbox" checked={@state.checked_tags[tag.tag_id]}
                  onClick={=> @search 0,
                    checked_tags: do =>
                      o = {}
                      o[tag.tag_id] =
                        $apply: (x) => not x
                      o
                  }
                />
                { tag.tag }
              </label>
            </p>
        }
      </div>
      <div style={position: 'fixed', top: '50%', left: 'calc(100% - 300px)', width: '300px', height: '50%', overflowY: 'scroll'}>
        { if @state.page isnt 1
            <p>
              <button type="button" onClick={=> @setPage(@state.page - 1)}>Previous Page</button>
            </p>
        }
        { for note in @state.notes
            <img key={note.note_id} src={note.media.thumb_url} style={width: 120, padding: 5} />
        }
        { if @state.notes.length is 50
            <p>
              <button type="button" onClick={=> @setPage(@state.page + 1)}>Next Page</button>
            </p>
        }
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
