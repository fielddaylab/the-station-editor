class Results
  constructor: (@parent, @games, @moreButton) ->
    @showMore()

  showMore: ->
    gamesToShow = @games[0..3]
    if gamesToShow.length isnt 0
      @games = @games[4..]
      if @games.length is 0
        @moreButton.hide()
      else
        @moreButton.show()
      appendTo @parent, '.row', {}, (row) =>
        appendGame = (game) =>
          appendTo row, '.siftr-cell.col-xs-6.col-sm-3', {}, (cell) =>
            if game?
              url = "#{SIFTR_URL}#{game.siftr_url ? game.game_id}"
              if game.go_to_note?
                url += '#' + game.go_to_note
              appendTo cell, 'a', href: url, (link) =>
                appendTo link, 'img.img-responsive.img-thumbnail.img-siftr-icon',
                  src: game.icon_url
                appendTo link, '.siftr-title', text: game.name
                markdown = new Showdown.converter()
                desc = appendTo link, '.siftr-description', html: markdown.makeHtml game.description
                desc.dotdotdot
                  watch: 'window'
                  height: 50
        appendGame gamesToShow[0]
        appendGame gamesToShow[1]
        appendTo row, '.clearfix.visible-xs-block'
        appendGame gamesToShow[2]
        appendGame gamesToShow[3]
      $('.siftr-description').trigger 'update'

class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris

      $('#menu-logout').click =>
        @aris.logout()
        @updateNav()

      $('#search-button').click =>
        searchText = $('#search-text').val()
        if searchText is ''
          $('#search-results').hide()
        else
          @aris.call 'games.searchSiftrs',
            search: $('#search-text').val()
          , (data: games) =>
            games =
              g for g in games when parseInt(g.published) isnt 0
            async.parallel( @getIconURL(game) for game in games
                          , =>
                            $('#rows-search').text ''
                            $('#search-results').show()
                            @search = new Results $('#rows-search'), games, $('#show-more-search')
                          )

      @aris.login undefined, undefined, =>
        @updateNav()

        @aris.call 'games.searchSiftrs',
          order_by: 'recent'
        , (data: games) =>
          games =
            g for g in games when parseInt(g.published) isnt 0
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          @recent = new Results $('#rows-recent'), games, $('#show-more-recent')
                        )

        @aris.call 'games.searchSiftrs',
          order_by: 'popular'
        , (data: games) =>
          games =
            g for g in games when parseInt(g.published) isnt 0
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          @popular = new Results $('#rows-popular'), games, $('#show-more-popular')
                        )

  getIconURL: (game) -> (cb) =>
    if game.icon_url?
      cb()
      return
    @aris.call 'notes.searchNotes',
      game_id: game.game_id
      note_count: 1
      order_by: 'recent'
    , (data: notes) =>
      if notes.length is 0
        if parseInt(game.icon_media_id) is 0
          game.icon_url = 'editor/img/uw_shield.png'
          cb()
        else
          @aris.call 'media.getMedia',
            media_id: game.icon_media_id
          , (data: media) =>
            game.icon_url = media.url
            cb()
      else
        game.icon_url = notes[0].media.data.url
        game.go_to_note = parseInt notes[0].note_id
        cb()

  updateNav: ->
    if @aris.auth?
      $('#span-username').text @aris.auth.username
      $('#dropdown-logged-in').show()
    else
      $('#dropdown-logged-in').hide()

window.app = new App
