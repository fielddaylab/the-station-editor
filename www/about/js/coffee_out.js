(function() {
  var App;

  App = (function() {
    function App() {
      $(function() {
        return FastClick.attach(document.body);
      });
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          cordovaFixLinks();
          $('#menu-logout').click(function() {
            _this.aris.logout();
            return _this.updateNav();
          });
          return _this.aris.login(void 0, void 0, function() {
            return _this.updateNav();
          });
        };
      })(this));
    }

    App.prototype.updateNav = function() {
      if (this.aris.auth != null) {
        $('#span-username').text(this.aris.auth.username);
        return $('#dropdown-logged-in').show();
      } else {
        return $('#dropdown-logged-in').hide();
      }
    };

    return App;

  })();

  window.app = new App;

}).call(this);
