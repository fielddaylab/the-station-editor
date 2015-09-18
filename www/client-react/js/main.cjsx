class window.Game
  constructor: (json) ->
    @game_id     = parseInt json.game_id
    @name        = json.name
    @description = json.description
    @latitude    = parseFloat json.map_latitude
    @longitude   = parseFloat json.map_longitude
    @zoom        = parseInt json.map_zoom_level

class window.User
  constructor: (json) ->
    @user_id      = parseInt json.user_id
    @display_name = json.display_name or json.user_name

class window.Tag
  constructor: (json) ->
    @icon_url = json.media?.data?.url
    @tag      = json.tag
    @tag_id   = parseInt json.tag_id

class window.Comment
  constructor: (json) ->
    @description = json.description
    @comment_id  = parseInt json.note_comment_id
    @user        = new User json.user
    @created     = new Date(json.created.replace(' ', 'T') + 'Z')

class window.Note
  constructor: (json) ->
    @note_id      = parseInt json.note_id
    @user         = new User json.user
    @description  = json.description
    @photo_url    =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.url
    @thumb_url    =
      if parseInt(json.media.data.media_id) is 0
        null
      else
        json.media.data.thumb_url
    @latitude     = parseFloat json.latitude
    @longitude    = parseFloat json.longitude
    @tag_id       = parseInt json.tag_id
    @created      = new Date(json.created.replace(' ', 'T') + 'Z')
    @player_liked = parseInt(json.player_liked) isnt 0
    @note_likes   = parseInt json.note_likes
    @comments     = for o in json.comments.data
      comment = new Comment o
      continue unless comment.description.match(/\S/)
      comment
    @published    = json.published

markdownConverter = new Showdown.converter();
markdown = (str) ->
  rendered = markdownConverter.makeHtml str
  rendered = rendered
    .replace(/<script[^>]*?>.*?<\/script>/gi, '')
    #.replace(/<[\/\!]*?[^<>]*?>/gi, '')
    .replace(/<style[^>]*?>.*?<\/style>/gi, '')
    .replace(/<![\s\S]*?--[ \t\n\r]*>/gi, '')
  __html: rendered

NoteView = React.createClass
  render: ->
    <div>
      <p><button type="button" onClick={@props.onBack}>Back</button></p>
      <p><img src={@props.note.photo_url} /></p>
      <p>{@props.note.description}</p>
      { for comment in @props.note.comments
          <div key={"comment-#{comment.comment_id}"}>
            <h4>{comment.user.display_name}, {comment.created.toLocaleString()}</h4>
            <p>{comment.description}</p>
          </div>
      }
    </div>

SearchBox = React.createClass
  handleChange: ->
    tags =
      tag for tag in @props.tags when @refs["searchTag#{tag.tag_id}"].getDOMNode().checked
    text = @refs.searchText.getDOMNode().value
    @props.onSearch tags, text

  render: ->
    <form>
      { for tag in @props.tags
          <p key={tag.tag_id}>
            <label>
              <input type="checkbox"
                ref="searchTag#{tag.tag_id}"
                checked={tag in @props.checkedTags}
                onChange={@handleChange}
              />
              { tag.tag }
            </label>
          </p>
      }
      <p>
        <input type="text" ref="searchText" value={@props.searchText} onChange={@handleChange} />
      </p>
    </form>

TopLevel = React.createClass
  getInitialState: ->
    notes: []
    viewing: null
    searching: false
    checkedTags: []
    searchText: ''
  componentDidMount: ->
    @handleSearch [], '', false

  render: ->
    <div>
      <h1>{ @props.game.name }</h1>
      <h2>A Siftr by { (u.display_name for u in @props.game.owners).join(', ') }</h2>
      <div dangerouslySetInnerHTML={markdown @props.game.description} />
      <div style={width: '500px', height: '500px'}>
        <GoogleMapReact
          center={[@props.game.latitude, @props.game.longitude]}
          zoom={@props.game.zoom}>
          { @state.notes.map (note) =>
              <div key={"marker-#{note.note_id}"} lat={note.latitude} lng={note.longitude}
                style={width: '10px', height: '10px', backgroundColor: 'black', cursor: 'pointer'}
                onClick={=> @setState viewing: note} />
          }
        </GoogleMapReact>
      </div>
      { if @state.viewing?
          <NoteView
            note={@state.viewing}
            onBack={=> @setState viewing: null}
          />
        else
          <div>
            <SearchBox
              tags={@props.game.tags}
              checkedTags={@state.checkedTags}
              searchText={@state.searchText}
              onSearch={@handleSearch}
            />
            { if @state.searching
                <p>Searching...</p>
              else
                @state.notes.map (note) =>
                  <a key={"thumb-#{note.note_id}"} href="#" onClick={=> @setState viewing: note}>
                    <img src={note.thumb_url} />
                  </a>
            }
          </div>
      }
    </div>

  handleSearch: (tags, text, wait = true) ->
    @setState
      checkedTags: tags
      searchText: text
    thisSearch = Date.now()
    @setState
      lastSearch: thisSearch
      searching: true
    setTimeout =>
      if thisSearch is @state.lastSearch
        @props.aris.call 'notes.searchNotes',
          game_id: @props.game.game_id
          order_by: 'recent'
          tag_ids:
            tag.tag_id for tag in tags
          search_terms:
            word for word in text.split(/\s+/) when word isnt ''
        , ({data: notes, returnCode}) =>
          if thisSearch is @state.lastSearch
            @setState searching: false
            if returnCode is 0
              @setState notes:
                for o in notes
                  n = new Note o
                  # hide notes that don't have photos
                  continue unless n.photo_url?
                  n
    , if wait then 250 else 0

$(document).ready ->

  aris = new Aris
  aris.call 'games.getGame',
    game_id: 3967
  , ({data: gameJson, returnCode}) ->
    if returnCode is 0 and gameJson?
      game = new Game gameJson

      aris.call 'tags.getTagsForGame',
        game_id: game.game_id
      , ({data: tags, returnCode}) =>
        if returnCode is 0
          game.tags =
            new Tag o for o in tags

          aris.call 'users.getUsersForGame',
            game_id: game.game_id
          , ({data: owners, returnCode}) =>
            if returnCode is 0
              game.owners =
                new User o for o in owners

              React.render <TopLevel game={game} aris={aris} />, document.getElementById('output')
