(function() {
  var App, app,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  App = (function() {
    function App() {
      this.parseLogInResult = __bind(this.parseLogInResult, this);
      $(document).ready((function(_this) {
        return function() {
          $.cookie.json = true;
          $('#button-login').click(function() {
            _this.login($('#text-username').val(), $('#text-password').val(), function() {
              if (_this.auth != null) {
                return _this.selectPage('#page-list');
              } else {
                $('#alert-login').text("Incorrect username or password.");
                return $('#alert-login').show();
              }
            });
            return false;
          });
          $('#button-new-acct').click(function() {
            return _this.selectPage('#page-new-acct');
          });
          $('#menu-logout').click(function() {
            _this.logout();
            return _this.selectPage('#page-login');
          });
          $('#menu-change-password').click(function() {
            return _this.selectPage('#page-change-password');
          });
          $('#button-create-acct').click(function() {
            var showAlert;
            showAlert = function(text) {
              $('#alert-new-acct').text(text);
              return $('#alert-new-acct').show();
            };
            if (__indexOf.call($('#text-new-email').val(), '@') < 0) {
              showAlert("Your email address is not valid.");
            } else if ($('#text-new-username').val().length < 1) {
              showAlert("Your username must be at least 1 character.");
            } else if ($('#text-new-password').val() !== $('#text-new-password-2').val()) {
              showAlert("Your passwords do not match.");
            } else if ($('#text-new-password').val().length < 6) {
              showAlert("Your password must be at least 6 characters.");
            } else {
              _this.callAris('users.createUser', {
                user_name: $('#text-new-username').val(),
                password: $('#text-new-password').val(),
                email: $('#text-new-email').val()
              }, function(res) {
                _this.parseLogInResult(res);
                if (_this.auth != null) {
                  $('#alert-new-acct').hide();
                  return _this.selectPage('#page-list');
                } else {
                  return showAlert("Couldn't create account: " + res.returnCodeDescription);
                }
              });
            }
            return false;
          });
          $('#button-change-password').click(function() {
            return console.log('TODO: change password');
          });
          $('#button-cancel-new-acct').click(function() {
            return _this.selectPage('#page-login');
          });
          _this.loadLogin();
          _this.updateNav();
          return _this.startingPage();
        };
      })(this));
    }

    App.prototype.startingPage = function() {
      if (this.auth != null) {
        return this.selectPage('#page-list');
      } else {
        return this.selectPage('#page-login');
      }
    };

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

    App.prototype.updateNav = function() {
      if (this.auth != null) {
        $('#span-username').text(this.auth.username);
        return $('#dropdown-logged-in').show();
      } else {
        return $('#dropdown-logged-in').hide();
      }
    };

    App.prototype.loadLogin = function() {
      return this.auth = $.cookie('auth');
    };

    App.prototype.parseLogInResult = function(_arg) {
      var returnCode, user;
      user = _arg.data, returnCode = _arg.returnCode;
      if (returnCode === 0) {
        this.auth = {
          user_id: parseInt(user.user_id),
          permission: 'read_write',
          key: user.read_write_key,
          username: user.user_name
        };
        $.cookie('auth', this.auth);
        return this.updateNav();
      }
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
        return function(res) {
          _this.parseLogInResult(res);
          return cb();
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.auth = null;
      $.removeCookie('auth');
      return this.updateNav();
    };

    App.prototype.selectPage = function(page) {
      $('.alert').hide();
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
