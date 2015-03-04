(function() {
  var App;

  App = (function() {
    function App() {
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          return _this.aris.login(void 0, void 0, function() {
            return $('body').text(JSON.stringify(_this.aris));
          });
        };
      })(this));
    }

    return App;

  })();

  window.app = new App;

}).call(this);
