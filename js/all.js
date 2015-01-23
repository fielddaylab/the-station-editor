(function() {
  var App, app;

  console.log('CoffeeScript loaded.');

  $.cookie.json = true;

  App = (function() {
    function App() {
      $(document).ready((function(_this) {
        return function() {
          $('#form-login').submit(function() {
            _this.login($('#text-username').val(), $('#text-password').val(), function() {
              if (_this.auth != null) {
                return _this.selectPage('#page-list');
              }
            });
            return false;
          });
          $('#button-logout').click(function() {
            _this.logout();
            return _this.selectPage('#page-login');
          });
          _this.loadLogin();
          if (_this.auth != null) {
            return _this.selectPage('#page-list');
          } else {
            return _this.selectPage('#page-login');
          }
        };
      })(this));
    }

    App.prototype.callAris = function(func, json, cb) {
      var req;
      if (cb == null) {
        cb = function(x) {
          this.arisResult = x;
          return console.log(x);
        };
      }
      if (this.auth != null) {
        json.auth = this.auth;
      }
      req = new XMLHttpRequest;
      req.onreadystatechange = (function(_this) {
        return function() {
          if (req.readyState === 4) {
            if (req.status === 200) {
              return cb(JSON.parse(req.responseText));
            } else {
              return cb(false);
            }
          }
        };
      })(this);
      req.open('POST', "http://dev.arisgames.org/server/json.php/v2." + func, true);
      req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      return req.send(JSON.stringify(json));
    };

    App.prototype.loadLogin = function() {
      return this.auth = $.cookie('auth');
    };

    App.prototype.login = function(username, password, cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.callAris('users.logIn', {
        user_name: username,
        password: password,
        permission: 'read_write'
      }, (function(_this) {
        return function(_arg) {
          var returnCode, user;
          user = _arg.data, returnCode = _arg.returnCode;
          if (returnCode === 0) {
            _this.auth = {
              user_id: parseInt(user.user_id),
              permission: 'read_write',
              key: user.read_write_key
            };
            $.cookie('auth', _this.auth);
          }
          return cb();
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.auth = null;
      return $.removeCookie('auth');
    };

    App.prototype.selectPage = function(page) {
      $('.page').hide();
      return $(page).show();
    };

    App.prototype.getGames = function(cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.callAris('games.getGamesForUser', {}, (function(_this) {
        return function(_arg) {
          var game, games;
          games = _arg.data;
          _this.games = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = games.length; _i < _len; _i++) {
              game = games[_i];
              _results.push({
                game_id: parseInt(game.game_id),
                name: game.name,
                description: game.description,
                icon_media_id: parseInt(game.icon_media_id),
                map_latitude: parseFloat(game.map_latitude),
                map_longitude: parseFloat(game.map_longitude),
                map_zoom_level: parseInt(game.map_zoom_level)
              });
            }
            return _results;
          })();
          return cb();
        };
      })(this));
    };

    App.prototype.getGameIcons = function(cb) {
      var game, _i, _len, _ref;
      if (cb == null) {
        cb = (function() {});
      }
      _ref = this.games;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        game = _ref[_i];
        if (game.icon_media == null) {
          this.callAris('media.getMedia', {
            media_id: game.icon_media_id
          }, (function(_this) {
            return function(_arg) {
              var media;
              media = _arg.data;
              game.icon_media = media;
              return _this.getGameIcons(cb);
            };
          })(this));
          return;
        }
      }
      return cb();
    };

    return App;

  })();

  app = new App;

  window.app = app;

}).call(this);
