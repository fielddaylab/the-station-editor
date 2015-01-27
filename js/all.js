(function() {
  var App, app, appendTo, parseElement,
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
                return _this.startingPage();
              } else {
                return _this.showAlert('Incorrect username or password.');
              }
            });
            return false;
          });
          $('#menu-logout').click(function() {
            _this.logout();
            return _this.selectPage('#page-login');
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

    App.prototype.redrawGameList = function() {
      var game, gameList, _i, _len, _ref, _results;
      gameList = $('#list-siftrs');
      gameList.text('');
      _ref = this.games;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        game = _ref[_i];
        _results.push((function(_this) {
          return function(game) {
            return appendTo(gameList, '.media', {}, function(media) {
              appendTo(media, '.media-left', {}, function(mediaLeft) {
                return appendTo(mediaLeft, 'img.media-object', {
                  src: game.icon_media.url,
                  width: '64px',
                  height: '64px'
                });
              });
              return appendTo(media, '.media-body', {}, function(mediaBody) {
                appendTo(mediaBody, 'h4.media-heading', {
                  text: game.name
                });
                appendTo(mediaBody, 'p', {
                  text: game.description
                });
                return appendTo(mediaBody, 'form', {}, function(form) {
                  return appendTo(form, '.form-group', {}, function(formGroup) {
                    appendTo(formGroup, 'a.btn.btn-primary', {
                      href: '#',
                      text: 'Edit Siftr'
                    }, function(button) {
                      return button.click(function() {
                        return _this.startEdit(game);
                      });
                    });
                    return appendTo(formGroup, 'a.btn.btn-default.disabled', {
                      href: '#',
                      text: 'Edit Tags'
                    }, function(button) {
                      return button.click(function() {});
                    });
                  });
                });
              });
            });
          };
        })(this)(game));
      }
      return _results;
    };

    App.prototype.updateGameList = function(cb) {
      if (cb == null) {
        cb = (function() {});
      }
      this.games = [];
      if (this.auth != null) {
        return this.getGames((function(_this) {
          return function() {
            return _this.getGameIcons(function() {
              return _this.getGameTags(function() {
                _this.redrawGameList();
                return cb();
              });
            });
          };
        })(this));
      } else {
        this.redrawGameList();
        return cb();
      }
    };

    App.prototype.addGameFromJson = function(json) {
      var game, i, newGame, _i, _len, _ref;
      newGame = {
        game_id: parseInt(json.game_id),
        name: json.name,
        description: json.description,
        icon_media_id: parseInt(json.icon_media_id),
        map_latitude: parseFloat(json.map_latitude),
        map_longitude: parseFloat(json.map_longitude),
        map_zoom_level: parseInt(json.map_zoom_level)
      };
      _ref = this.games;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        game = _ref[i];
        if (game.game_id === newGame.game_id) {
          this.games[i] = newGame;
          return newGame;
        }
      }
      this.games.push(newGame);
      return newGame;
    };

    App.prototype.getGames = function(cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.callAris('games.getGamesForUser', {}, (function(_this) {
        return function(_arg) {
          var games, json, _i, _len;
          games = _arg.data;
          _this.games = [];
          for (_i = 0, _len = games.length; _i < _len; _i++) {
            json = games[_i];
            _this.addGameFromJson(json);
          }
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

    App.prototype.selectedIcon = function() {
      return $('#div-icon-group').removeClass('has-success');
    };

    App.prototype.resetIcon = function() {
      var newThumb;
      $('#div-icon-group').addClass('has-success');
      $('#div-icon-input').fileinput('clear');
      $('#div-icon-thumb').html('');
      newThumb = $('<img />', {
        src: this.currentGame.icon_media.url
      });
      return $('#div-icon-thumb').append(newThumb);
    };

    App.prototype.updateSiftrName = function() {
      var box, _ref;
      box = $('#text-siftr-name');
      if (box.val() === ((_ref = this.currentGame) != null ? _ref.name : void 0)) {
        return box.parent().addClass('has-success');
      } else {
        return box.parent().removeClass('has-success');
      }
    };

    App.prototype.updateSiftrDesc = function() {
      var box, _ref;
      box = $('#text-siftr-desc');
      if (box.val() === ((_ref = this.currentGame) != null ? _ref.description : void 0)) {
        return box.parent().addClass('has-success');
      } else {
        return box.parent().removeClass('has-success');
      }
    };

    App.prototype.updateSiftrMap = function() {
      var equalish, pn;
      if (this.currentGame == null) {
        return;
      }
      pn = this.map.getCenter();
      equalish = function(x, y) {
        return Math.abs(x - y) < 0.00001;
      };
      if (equalish(pn.lat(), this.currentGame.map_latitude)) {
        if (equalish(pn.lng(), this.currentGame.map_longitude)) {
          if (this.map.getZoom() === this.currentGame.map_zoom_level) {
            $('#div-map-group').addClass('has-success');
            return;
          }
        }
      }
      return $('#div-map-group').removeClass('has-success');
    };

    App.prototype.createMap = function(parent, _arg) {
      var lat, lng, zoom;
      lat = _arg.lat, lng = _arg.lng, zoom = _arg.zoom;
      if (this.map != null) {
        this.map.setCenter({
          lat: lat,
          lng: lng
        });
        this.map.setZoom(zoom);
      } else {
        this.map = new google.maps.Map($('#the-map')[0], {
          center: {
            lat: lat,
            lng: lng
          },
          zoom: zoom
        });
        this.map.addListener('idle', (function(_this) {
          return function() {
            return _this.updateSiftrMap();
          };
        })(this));
      }
      return parent.append(this.map.getDiv());
    };

    App.prototype.startEdit = function(game) {
      if (game == null) {
        game = this.currentGame;
      }
      this.currentGame = game;
      $('#text-siftr-name').val(game.name);
      this.updateSiftrName();
      $('#text-siftr-desc').val(game.description);
      this.updateSiftrDesc();
      this.resetIcon();
      this.createMap($('#div-google-map'), {
        lat: game.map_latitude,
        lng: game.map_longitude,
        zoom: game.map_zoom_level
      });
      this.updateSiftrMap();
      return this.selectPage('#page-edit');
    };

    App.prototype.getIconID = function(cb) {
      var base64, dataURL, ext, extmap, k, v;
      if (cb == null) {
        cb = (function() {});
      }
      if ($('#div-icon-group').hasClass('has-success')) {
        return cb(this.currentGame.icon_media_id);
      } else {
        dataURL = $('#file-siftr-icon')[0].files[0].result;
        extmap = {
          jpg: 'data:image/jpeg;base64,',
          png: 'data:image/png;base64,',
          gif: 'data:image/gif;base64,'
        };
        ext = null;
        base64 = null;
        for (k in extmap) {
          v = extmap[k];
          if (dataURL.indexOf(v) === 0) {
            ext = k;
            base64 = dataURL.substring(v.length);
          }
        }
        if (!((ext != null) && (base64 != null))) {
          cb(false);
          return;
        }
        return this.callAris('media.createMedia', {
          game_id: this.currentGame.game_id,
          file_name: "upload." + ext,
          data: base64
        }, (function(_this) {
          return function(_arg) {
            var media;
            media = _arg.data;
            return cb(media.media_id);
          };
        })(this));
      }
    };

    App.prototype.editSave = function(cb) {
      var pn;
      if (cb == null) {
        cb = (function() {});
      }
      $('#spinner-edit-save').show();
      pn = this.map.getCenter();
      return this.getIconID((function(_this) {
        return function(media_id) {
          return _this.callAris('games.updateGame', {
            game_id: _this.currentGame.game_id,
            name: $('#text-siftr-name').val(),
            description: $('#text-siftr-desc').val(),
            map_latitude: pn.lat(),
            map_longitude: pn.lng(),
            map_zoom_level: _this.map.getZoom(),
            icon_media_id: media_id
          }, function(_arg) {
            var json, newGame;
            json = _arg.data;
            newGame = _this.addGameFromJson(json);
            return _this.getGameIcons(function() {
              return _this.getGameTags(function() {
                _this.redrawGameList();
                $('#spinner-edit-save').hide();
                _this.startEdit(newGame);
                return cb(newGame);
              });
            });
          });
        };
      })(this));
    };

    App.prototype.startNewSiftr = function(cb) {
      if (cb == null) {
        cb = (function() {});
      }
      this.createMap($('#div-new-google-map'), {
        lat: 43.071644,
        lng: -89.400658,
        zoom: 14
      });
      this.updateTagMinus();
      return this.selectPage('#page-new');
    };

    App.prototype.updateTagMinus = function() {
      if ($('#div-new-tags')[0].children.length === 0) {
        return $('#button-new-minus-tag').addClass('disabled');
      } else {
        return $('#button-new-minus-tag').removeClass('disabled');
      }
    };

    App.prototype.addTag = function() {
      appendTo($('#div-new-tags'), '.media', {}, (function(_this) {
        return function(media) {
          appendTo(media, '.media-left', {}, function(mediaLeft) {
            return appendTo(mediaLeft, 'img.media-object', {
              src: 'http://dev.arisgames.org/server/gamedata/v2/265/aris998d7b671a704a178bd2611b0f167208.jpg',
              width: '64px',
              height: '64px'
            });
          });
          return appendTo(media, '.media-body', {}, function(mediaBody) {
            return appendTo(mediaBody, 'input.form-control', {
              type: 'text',
              placeholder: 'Tag'
            });
          });
        };
      })(this));
      return this.updateTagMinus();
    };

    App.prototype.removeTag = function() {
      var tags;
      tags = $('#div-new-tags')[0];
      if (tags.children.length > 0) {
        tags.removeChild(tags.children[tags.children.length - 1]);
      }
      return this.updateTagMinus();
    };

    return App;

  })();

  parseElement = function(str) {
    var classes, eatWord, id, tag;
    eatWord = function() {
      var dot, hash, word;
      hash = str.indexOf('#');
      dot = str.indexOf('.');
      if (hash === -1) {
        hash = 9999;
      }
      if (dot === -1) {
        dot = 9999;
      }
      word = str.slice(0, Math.min(hash, dot));
      str = str.slice(word.length);
      return word;
    };
    tag = eatWord() || 'div';
    classes = [];
    id = null;
    while (str !== '') {
      if (str[0] === '.') {
        str = str.slice(1);
        classes.push(eatWord());
      } else if (str[0] === '#') {
        str = str.slice(1);
        id = eatWord();
      } else {
        return false;
      }
    }
    return {
      tag: tag,
      classes: classes,
      id: id
    };
  };

  appendTo = function(parent, haml, attrs, init) {
    var c, child, classes, id, tag, _i, _len, _ref;
    if (haml == null) {
      haml = '';
    }
    if (attrs == null) {
      attrs = {};
    }
    if (init == null) {
      init = (function() {});
    }
    _ref = parseElement(haml), tag = _ref.tag, classes = _ref.classes, id = _ref.id;
    for (_i = 0, _len = classes.length; _i < _len; _i++) {
      c = classes[_i];
      if (attrs["class"] == null) {
        attrs["class"] = '';
      }
      attrs["class"] += " " + c;
    }
    if (id != null) {
      attrs.id = id;
    }
    child = $("<" + tag + " />", attrs);
    init(child);
    parent.append(' ');
    parent.append(child);
    parent.append(' ');
    return child;
  };

  app = new App;

  window.app = app;

}).call(this);
