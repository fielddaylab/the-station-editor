class App
  constructor: ->
    $(document).ready =>
      @aris = new Aris
      @aris.login undefined, undefined, =>
        $('body').text JSON.stringify @aris

window.app = new App
