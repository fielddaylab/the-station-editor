class App
  constructor: ->
    $ -> FastClick.attach document.body
    $(document).ready =>
      @aris = new Aris
      cordovaFixLinks()

      $('#menu-logout').click =>
        @aris.logout()
        @updateNav()

      @aris.login undefined, undefined, =>
        @updateNav()

  updateNav: ->
    if @aris.auth?
      $('#span-username').text @aris.auth.username
      $('#dropdown-logged-in').show()
    else
      $('#dropdown-logged-in').hide()

window.app = new App
