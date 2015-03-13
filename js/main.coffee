class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris

      $('#menu-logout').click =>
        @aris.logout()
        @updateNav()

      $('#search-button').click =>
        @aris.call 'games.searchSiftrs',
          count: 4
          search: $('#search-text').val()
        , (data: games) =>
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          cells = $('#row-search').children()
                          for game, i in games
                            @updateCell cells[i], game
                          $('#search-results').show()
                        )

      @aris.login undefined, undefined, =>
        @updateNav()

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'recent'
        , (data: games) =>
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          cells = $('#row-recent').children()
                          for game, i in games
                            @updateCell cells[i], game
                        )

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'popular'
        , (data: games) =>
          async.parallel( @getIconURL(game) for game in games
                        , =>
                          cells = $('#row-popular').children()
                          for game, i in games
                            @updateCell cells[i], game
                        )

  getIconURL: (game) -> (cb) =>
    @aris.call 'media.getMedia',
      media_id: game.icon_media_id
    , (data: media) =>
      game.icon_url = media.url
      cb()

  updateCell: (cell, game) =>
    $(cell).find('a').attr 'href',
      "#{SIFTR_URL}?#{game.siftr_url ? game.game_id}"
    $(cell).find('img').attr 'src',
      if parseInt(game.icon_media_id) is 0
        'editor/img/uw_shield.png'
      else
        game.icon_url

  updateNav: ->
    if @aris.auth?
      $('#span-username').text @aris.auth.username
      $('#dropdown-logged-in').show()
    else
      $('#dropdown-logged-in').hide()

window.app = new App
