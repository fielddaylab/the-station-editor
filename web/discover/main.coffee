$ = require 'jquery'
React = require 'react'
ReactDOM = require 'react-dom'
{make, child, raw, props} = require '../shared/react-writer.js'
{Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} = require '../shared/aris.js'
update = require 'react-addons-update'
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
    logged_in: window.localStorage['aris-auth']?

  componentDidMount: ->
    @recent  1
    @popular 1

  fetchIcons: (games) ->
    games.forEach (game) =>
      unless @state.icons[game.game_id]? or parseInt(game.icon_media_id) is 0
        @props.aris.call 'media.getMedia',
          media_id: game.icon_media_id
        , ({returnCode, data: media}) =>
          if returnCode is 0 and media?
            @setState (prevState) => update prevState,
              icons: do =>
                obj = {}
                obj[game.game_id] = $set: media.thumb_url
                obj

  fetchOwners: (games) ->
    games.forEach (game) =>
      unless @state.owners[game.game_id]?
        @props.aris.getUsersForGame
          game_id: game.game_id
        , ({returnCode, data: users}) =>
          if returnCode is 0 and users?
            @setState (prevState) => update prevState,
              owners: do =>
                obj = {}
                obj[game.game_id] = $set: users
                obj
            @fetchOwnerPictures users

  fetchOwnerPictures: (owners) ->
    owners.forEach (user) =>
      unless @state.owner_pictures[user.user_id]? or parseInt(user.media_id) is 0
        @props.aris.call 'media.getMedia',
          media_id: user.media_id
        , ({returnCode, data: media}) =>
          if returnCode is 0 and media?
            @setState (prevState) => update prevState,
              owner_pictures: do =>
                obj = {}
                obj[user.user_id] = $set: media.thumb_url
                obj

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

  search: (page, str = @state.text) ->
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
        @search 1, str
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

    make 'div', =>
      child 'div#banner.section.dark_bg', =>
        child 'div#top_bar', style: {height: 50, padding: 30}, =>
          child 'a', href: (if window.cordova? then '../index.html' else '..'), =>
            child 'div.top_bar_logo', style: {width: 57, height: 50}, =>
              child 'img',
                src: "../assets/logos/siftr-nav-logo.png"
                style:
                  width: '100%'
                  height: '100%'
          unless @state.logged_in
            child 'a', href: (if window.cordova? then '../editor-react/index.html#signup' else '../login/#signup'), =>
              child 'div.top_bar_link.signup_button', =>
                raw 'SIGN UP'
            child 'a', href: (if window.cordova? then '../editor-react/index.html' else '../login'), =>
              child 'div.top_bar_link', =>
                raw 'LOGIN'
          child 'a', href: '', =>
            child 'div.top_bar_link', style: {color: 'rgb(235,197,0)'}, =>
              raw 'DISCOVER'
          if @state.logged_in
            child 'a', href: (if window.cordova? then '../editor-react/index.html#account' else '../editor/#account'), =>
              child 'div.top_bar_link', =>
                raw 'MY ACCOUNT'
            child 'a', href: (if window.cordova? then '../editor-react/index.html' else '../editor'), =>
              child 'div.top_bar_link', =>
                raw 'MY SIFTRS'
        child 'div.spacer', style: height: 20
        child 'div', style: {maxWidth: '100%', width:'600px', margin:'0px auto', color:'#FF0000'}, =>
          child 'img', src: "../assets/logos/siftr-main-logo.png", style: width: '100%'
        child 'div.spacer', style: height: 30
        child 'div#slogan', =>
          raw 'EXPLORE YOUR WORLD, SHARE YOUR DISCOVERIES'
        child 'div.spacer', style: height: 60
        child 'div', style: {width: '600px', maxWidth: 'calc(100% - 10px)', margin: '0px auto'}, =>
          child 'input',
            type: 'text'
            style: {width: '100%', fontSize: 20, padding: '12px 20px', borderRadius: 25}
            placeholder: 'Search for a Siftr...'
            value: @state.text
            onChange: (e) => @setText e.target.value
        child 'div.spacer', style: height: 60

      sections.forEach ({header, identifier}) =>
        child 'div.section.white_bg.list_section', key: "section_#{identifier}", =>
          child 'div', style: {textAlign: 'center', letterSpacing: 3, padding: 20}, =>
            child 'h2', => raw header
            child 'h4', =>
              child 'b', =>
                props
                  style: cursor: 'pointer'
                  onClick: => @[identifier](@state[identifier].page - 1) unless @state[identifier].page is 1
                raw ' < '
              raw "page #{@state[identifier].page}"
              child 'b', =>
                props
                  style: cursor: 'pointer'
                  onClick: => @[identifier](@state[identifier].page + 1)
                raw ' > '
          for game in @state[identifier].games
            url = game.siftr_url or game.game_id
            child 'div.list_entry', key: game.game_id, =>
              child 'div.list_entry_faded', =>
                child 'a.list_link', href: (if window.cordova? then "../client-react/index.html?#{url}" else "../#{url}"), target: (if window.cordova? then '' else '_blank'), =>
                  child 'img.list_image',
                    src: @state.icons[game.game_id] ? '../assets/logos/siftr-nav-logo.png'
                  child 'h3.list_name', => raw game.name
                child 'div.list_description', dangerouslySetInnerHTML: renderMarkdown game.description
                child 'div.list_fadeout'
              child 'div.list_credit', =>
                if @state.owners[game.game_id]?
                  owner = @state.owners[game.game_id][0]
                  child 'p', =>
                    if @state.owner_pictures[owner.user_id]?
                      child 'img.owner_picture', src: @state.owner_pictures[owner.user_id]
                    else
                      chars =
                        word[0] for word in owner.display_name.split(/\W+/) when word isnt ''
                      child 'span.owner_picture', =>
                        raw chars.join('')[0..1].toUpperCase()
                    raw "By #{owner.display_name}"
          child 'div', style: clear: 'both'

$(document).ready ->
  ReactDOM.render React.createElement(App, aris: new Aris), document.getElementById('the-container')
