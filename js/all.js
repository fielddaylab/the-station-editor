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
            $('#spinner-login').show();
            _this.login($('#text-username').val(), $('#text-password').val(), function() {
              $('#spinner-login').hide();
              if (_this.auth != null) {
                return _this.selectPage('#page-list');
              } else {
                return _this.showAlert('Incorrect username or password.');
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
            if (__indexOf.call($('#text-new-email').val(), '@') < 0) {
              _this.showAlert("Your email address is not valid.");
            } else if ($('#text-new-username').val().length < 1) {
              _this.showAlert("Your username must be at least 1 character.");
            } else if ($('#text-new-password').val() !== $('#text-new-password-2').val()) {
              _this.showAlert("Your passwords do not match.");
            } else if ($('#text-new-password').val().length < 6) {
              _this.showAlert("Your password must be at least 6 characters.");
            } else {
              _this.callAris('users.createUser', {
                user_name: $('#text-new-username').val(),
                password: $('#text-new-password').val(),
                email: $('#text-new-email').val()
              }, function(res) {
                if (res.returnCode !== 0) {
                  return _this.showAlert("Couldn't create account: " + res.returnCodeDescription);
                } else {
                  _this.parseLogInResult(res);
                  $('#the-alert').hide();
                  return _this.startingPage();
                }
              });
            }
            return false;
          });
          $('#button-change-password').click(function() {
            if ($('#text-change-password').val() !== $('#text-change-password-2').val()) {
              _this.showAlert("Your new passwords do not match.");
            } else if ($('#text-change-password').val().length < 6) {
              _this.showAlert("Your new password must be at least 6 characters.");
            } else {
              _this.callAris('users.changePassword', {
                user_name: _this.auth.username,
                old_password: $('#text-old-password').val(),
                new_password: $('#text-change-password').val()
              }, function(res) {
                if (res.returnCode !== 0) {
                  return _this.showAlert("Couldn't change password: " + res.returnCodeDescription);
                } else {
                  _this.parseLogInResult(res);
                  $('#the-alert').hide();
                  return _this.startingPage();
                }
              });
            }
            return false;
          });
          $('#button-cancel-new-acct').click(function() {
            return _this.selectPage('#page-login');
          });
          _this.loadLogin();
          _this.updateNav();
          return _this.updateGameList(function() {
            return _this.startingPage();
          });
        };
      })(this));
    }

    App.prototype.showAlert = function(str) {
      $('#the-alert').text(str);
      return $('#the-alert').show();
    };

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
          return _this.updateGameList(cb);
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.auth = null;
      $.removeCookie('auth');
      return this.updateNav();
    };

    App.prototype.selectPage = function(page) {
      $('#the-alert').hide();
      $('.page').hide();
      return $(page).show();
    };

    App.prototype.updateGameList = function(cb) {
      var gameList, updateDom;
      if (cb == null) {
        cb = (function() {});
      }
      this.games = [];
      gameList = $('#list-siftrs');
      gameList.text('');
      updateDom = (function(_this) {
        return function() {
          var game, _fn, _i, _len, _ref;
          _ref = _this.games;
          _fn = function(game) {
            var media;
            media = $('<div />', {
              "class": 'media'
            });
            (function() {
              var linkEdit;
              linkEdit = $('<a />', {
                href: '#'
              });
              (function() {
                var mediaBody, mediaLeft;
                mediaLeft = $('<div />', {
                  "class": 'media-left'
                });
                (function() {
                  return mediaLeft.append($('<img />', {
                    "class": 'media-object',
                    src: game.icon_media.url,
                    width: '64px',
                    height: '64px'
                  }));
                })();
                linkEdit.append(mediaLeft);
                mediaBody = $('<div />', {
                  "class": 'media-body'
                });
                (function() {
                  mediaBody.append($('<h4 />', {
                    "class": 'media-heading',
                    text: game.name
                  }));
                  return mediaBody.append(game.description);
                })();
                return linkEdit.append(mediaBody);
              })();
              linkEdit.click(function() {
                return _this.startEdit(game);
              });
              return media.append(linkEdit);
            })();
            return gameList.append(media);
          };
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            game = _ref[_i];
            _fn(game);
          }
          return cb();
        };
      })(this);
      if (this.auth != null) {
        return this.getGames((function(_this) {
          return function() {
            return _this.getGameIcons(function() {
              return _this.getGameTags(function() {
                return updateDom();
              });
            });
          };
        })(this));
      } else {
        return updateDom();
      }
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
              game.icon_media = _arg.data;
              return _this.getGameIcons(cb);
            };
          })(this));
          return;
        }
      }
      return cb();
    };

    App.prototype.getGameTags = function(cb) {
      var game, _i, _len, _ref;
      if (cb == null) {
        cb = (function() {});
      }
      _ref = this.games;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        game = _ref[_i];
        if (game.tags == null) {
          this.callAris('tags.getTagsForGame', {
            game_id: game.game_id
          }, (function(_this) {
            return function(_arg) {
              game.tags = _arg.data;
              return _this.getGameTags(cb);
            };
          })(this));
          return;
        }
      }
      return cb();
    };

    App.prototype.startEdit = function(game) {
      var divTags, inputGroup, tag, textBox, _i, _len, _ref;
      if (game == null) {
        game = this.currentGame;
      }
      this.currentGame = game;
      $('#text-siftr-name').val(game.name);
      $('#text-siftr-desc').val(game.description);
      divTags = $('#div-edit-tags');
      divTags.text('');
      _ref = game.tags;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tag = _ref[_i];
        inputGroup = $('<div />', {
          "class": 'form-group'
        });
        textBox = $('<input />', {
          type: 'text',
          "class": 'form-control'
        });
        textBox.val(tag.tag);
        inputGroup.append(textBox);
        divTags.append(inputGroup);
      }
      this.updateTagsMinus();
      if (this.map != null) {
        this.map.setCenter({
          lat: game.map_latitude,
          lng: game.map_longitude
        });
        this.map.setZoom(game.map_zoom_level);
      } else {
        this.map = new google.maps.Map($('#div-google-map')[0], {
          center: {
            lat: game.map_latitude,
            lng: game.map_longitude
          },
          zoom: game.map_zoom_level
        });
      }
      return this.selectPage('#page-edit');
    };

    App.prototype.updateTagsMinus = function() {
      if ($('#div-edit-tags')[0].children.length === 0) {
        return $('#button-minus-tag').addClass('disabled');
      } else {
        return $('#button-minus-tag').removeClass('disabled');
      }
    };

    App.prototype.removeTag = function() {
      var divTags;
      divTags = $('#div-edit-tags');
      if (divTags[0].children.length > 0) {
        divTags[0].removeChild(divTags[0].lastChild);
      }
      return this.updateTagsMinus();
    };

    App.prototype.addTag = function() {
      var divTags, inputGroup, textBox;
      divTags = $('#div-edit-tags');
      inputGroup = $('<div />', {
        "class": 'form-group'
      });
      textBox = $('<input />', {
        type: 'text',
        "class": 'form-control'
      });
      inputGroup.append(textBox);
      divTags.append(inputGroup);
      return this.updateTagsMinus();
    };

    return App;

  })();

  app = new App;

  window.app = app;

}).call(this);
