$ = require 'jquery'
React = require 'react'
ReactDOM = require 'react-dom'
{make, child, raw, props} = require '../shared/react-writer.js'
{Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} = require '../shared/aris.js'
{markdown} = require 'markdown'

renderMarkdown = (str) ->
  __html: markdown.toHTML str

App = React.createClass
  displayName: 'App'

  getInitialState: ->
    recent:
      page: 0
      games: []
    popular:
      page: 0
      games: []
    search:
      page: 0
      games: []
    text: ''
    icons: {}
    owners: {}
    owner_pictures: {}

  componentDidMount: ->
    @recent  1
    @popular 1

  fetchIcons: (games) ->

  fetchOwners: (games) ->

  fetchOwnerPictures: (owners) ->

  recent: (page) ->
    @props.aris.call 'games.searchSiftrs',
      count: 4
      offset: (page - 1) * 4
      order_by: 'recent'
    , ({returnCode, data: games}) =>
      if returnCode is 0 and games?
        @setState
          recent: {page, games}
        @fetchIcons games
        @fetchOwners games

  popular: (page) ->
    @props.aris.call 'games.searchSiftrs',
      count: 4
      offset: (page - 1) * 4
      order_by: 'popular'
    , ({returnCode, data: games}) =>
      if returnCode is 0 and games?
        @setState
          popular: {page, games}
        @fetchIcons games
        @fetchOwners games

  search: (str, page) ->
    @props.aris.call 'games.searchSiftrs',
      count: 4
      offset: (page - 1) * 4
      search: str
    , ({returnCode, data: games}) =>
      if returnCode is 0 and games?
        @setState
          search: {page, games}
        @fetchIcons games
        @fetchOwners games

  setText: (str) ->
    @setState text: str
    thisSearch = @lastSearch = Date.now()
    setTimeout =>
      if thisSearch is @lastSearch
        @search str, 1
    , 300

  render: ->
    sections =
      [ { header: 'RECENT SIFTRS'
        , identifier: 'recent'
        }
      , { header: 'POPULAR SIFTRS'
        , identifier: 'popular'
        }
      ]
    if @state.text isnt ''
      sections.unshift
        header: "RESULTS FOR \"#{@state.text}\""
        identifier: 'search'

    <div>
      <div id="banner" className="section dark_bg" style={position:'relative',minHeight:300,backgroundImage:"url('assets/photos/siftr-header.jpg')",backgroundSize:'cover'}>
        <div id="top_bar" style={height:50, padding:30}>
          <a href=".."><div className="top_bar_logo" style={width:57,height:50}><img src="assets/logos/siftr-nav-logo.png" style={width:'100%',height:'100%'}></img></div></a>
          <a href=""><div className="top_bar_link" style={color: 'rgb(235,197,0)'}>DISCOVER</div></a>
          <a href="../editor"><div className="top_bar_link">MY SIFTRS</div></a>
        </div>
        <div className="spacer" style={height:20}></div>
        <div style={width:'600px', height:'280px', margin:'0px auto', color:'#FF0000'}><img src="assets/logos/siftr-main-logo.png" style={width:'100%', height:'100%'}></img></div>
        <div className="spacer" style={height:30}></div>
        <div style={width:'100%', height:'30px', margin:'0px auto', textAlign:'center', fontSize:'20px', letterSpacing:'5px', fontWeight:'light', color:'#FFFFFF'}>EXPLORE YOUR WORLD, SHARE YOUR DISCOVERIES</div>
        <div className="spacer" style={height:60}></div>
        <div style={width: '300px', margin: '0px auto'}>
          <input type="text" style={width:'100%', fontSize: 20} placeholder="Search for a Siftr..." value={@state.text} onChange={(e) => @setText e.target.value}></input>
        </div>
        <div className="spacer" style={height:60}></div>
      </div>

      { sections.map ({header, identifier}) =>
          <div className="section white_bg" key={"section_#{identifier}"}>
            <div style={letterSpacing:3, padding:20}>
              {header}
              <b style={
                cursor: 'pointer'
              } onClick={=> @[identifier](@state[identifier].page - 1) unless @state[identifier].page is 1}>
                {' < '}
              </b>
              page {@state[identifier].page}
              <b style={
                cursor: 'pointer'
              } onClick={=> @[identifier](@state[identifier].page + 1)}>
                {' > '}
              </b>
            </div>
            <div className="siftr_list">

            { for game in @state[identifier].games
                <div className="list_el" key={game.game_id}>
                  <div className="list_el_img">
                    <img src="assets/photos/hiking.jpg" style={width:'100%', height:'100%'}></img>
                  </div>
                  <div className="list_el_title">{game.name}</div>
                  <div className="list_el_description" dangerouslySetInnerHTML={renderMarkdown game.description} />
                  <div className="list_el_line"></div>
                  <div className="list_el_owner">
                    <div className="list_el_owner_icon">AB</div>
                    <div className="list_el_owner_name">By You</div>
                  </div>
                </div>
            }
            <div style={clear: 'both'} />

            </div>
          </div>
      }
    </div>

$(document).ready ->
  ReactDOM.render React.createElement(App, aris: new Aris), document.getElementById('the-container')
