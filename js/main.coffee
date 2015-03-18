class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris

      $('.siftr-description').dotdotdot
        watch: 'window'
        height: 50

      $('#menu-logout').click =>
        @aris.logout()
        @updateNav()

      $('#search-button').click =>
        searchText = $('#search-text').val()
        if searchText is ''
          $('#search-results').hide()
        else
          @aris.call 'games.searchSiftrs',
            count: 4
            search: $('#search-text').val()
          , (data: games) =>
            async.parallel( @getIconURL(game) for game in games
                          , =>
                            cells = $('#row-search').children('.siftr-cell')
                            for cell, i in cells
                              @updateCell cell, games[i]
                            $('#search-results').show()
                            $('.siftr-description').trigger 'update'
                          )

      @aris.login undefined, undefined, =>
        @updateNav()

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'recent'
        , (data: games) =>
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          cells = $('#row-recent').children('.siftr-cell')
                          for cell, i in cells
                            @updateCell cell, games[i]
                        )

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'popular'
        , (data: games) =>
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          cells = $('#row-popular').children('.siftr-cell')
                          for cell, i in cells
                            @updateCell cell, games[i]
                        )

  getIconURL: (game) -> (cb) =>
    @aris.call 'notes.searchNotes',
      game_id: game.game_id
      note_count: 1
      order_by: 'recent'
    , (data: notes) =>
      if notes.length is 0
        @aris.call 'media.getMedia',
          media_id: game.icon_media_id
        , (data: media) =>
          game.icon_url = media.url
          cb()
      else
        game.icon_url = notes[0].media.data.url
        game.go_to_note = parseInt notes[0].note_id
        cb()

  updateCell: (cell, game) =>
    if game?
      link = "#{SIFTR_URL}#{game.siftr_url ? game.game_id}"
      if game.go_to_note?
        link += '#' + game.go_to_note
      $(cell).find('a').attr 'href', link
      $(cell).find('img').attr 'src',
        if parseInt(game.icon_media_id) is 0
          'editor/img/uw_shield.png'
        else
          game.icon_url
      $(cell).find('img').show()
      $(cell).find('.siftr-title').text game.name
      $(cell).find('.siftr-description').text game.description
    else
      $(cell).find('a').attr 'href', '#'
      $(cell).find('img').removeAttr 'src'
      $(cell).find('img').hide()
      $(cell).find('.siftr-title').text ''
      $(cell).find('.siftr-description').text ''

  updateNav: ->
    if @aris.auth?
      $('#span-username').text @aris.auth.username
      $('#dropdown-logged-in').show()
    else
      $('#dropdown-logged-in').hide()

window.app = new App
