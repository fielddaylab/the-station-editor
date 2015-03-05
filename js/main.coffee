class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris

      $('#menu-logout').click =>
        @aris.logout()
        @updateNav()

      @aris.login undefined, undefined, =>
        @updateNav()

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'recent'
        , (data: games) =>
          async.series( @getIconURL(game) for game in games
                      , =>
                        cells = $('#row-recent').children()
                        for game, i in games
                          @updateCell cells[i], game
                      )

        @aris.call 'games.searchSiftrs',
          count: 4
          order_by: 'popular'
        , (data: games) =>
          async.series( @getIconURL(game) for game in games
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
      if game.siftr_url?
        "#{SIFTR_URL}#{game.siftr_url}"
      else
        "#{SIFTR_URL}?#{game.game_id}"
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
