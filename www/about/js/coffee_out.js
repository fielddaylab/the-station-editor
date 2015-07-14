(function() {
  var App;

  App = (function() {
    function App() {
      $(function() {
        return FastClick.attach(document.body);
      });
      $(document).ready((function(_this) {
        return function() {
          var elt, _i, _len, _ref;
          _this.aris = new Aris;
          if (window.cordova != null) {
            _ref = $('.cordova-internal-link');
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              elt = _ref[_i];
              elt.href = elt.href.replace(/\/$/g, '/index.html').replace(/\/\#/g, '/index.html#');
            }
          }
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
