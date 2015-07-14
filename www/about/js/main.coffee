class App
  constructor: ->
    $ -> FastClick.attach document.body
    $(document).ready =>
      @aris = new Aris

      if window.cordova?
        for elt in $('.cordova-internal-link')
          elt.href = elt.href.replace(/\/$/g, '/index.html').replace(/\/\#/g, '/index.html#')

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
