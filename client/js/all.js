(function() {
  var App, Comment, Game, Note, Tag, User, app;

  Game = (function() {
    function Game(json) {
      this.game_id = parseInt(json.game_id);
      this.name = json.name;
      this.latitude = parseFloat(json.map_latitude);
      this.longitude = parseFloat(json.map_longitude);
      this.zoom = parseInt(json.map_zoom_level);
    }

    return Game;

  })();

  User = (function() {
    function User(json) {
      this.user_id = parseInt(json.user_id);
      this.display_name = json.display_name;
    }

    return User;

  })();

  Tag = (function() {
    function Tag(json) {
      this.icon_url = json.media.data.url;
      this.tag = json.tag;
      this.tag_id = parseInt(json.tag_id);
    }

    return Tag;

  })();

  Comment = (function() {
    function Comment(json) {
      this.description = json.description;
      this.comment_id = parseInt(json.note_comment_id);
      this.user = new User(json.user);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
    }

    return Comment;

  })();

  Note = (function() {
    function Note(json) {
      var o;
      this.user = new User(json.user);
      this.description = json.description;
      this.photo_url = json.media.data.url;
      this.latitude = parseFloat(json.latitude);
      this.longitude = parseFloat(json.longitude);
      this.tag_id = parseInt(json.tag_id);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.player_liked = parseInt(json.player_liked) !== 0;
      this.note_likes = parseInt(json.note_likes);
      this.comments = (function() {
        var i, len, ref, results;
        ref = json.comments.data;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          o = ref[i];
          results.push(new Comment(o));
        }
        return results;
      })();
    }

    return Note;

  })();

  App = (function() {
    function App() {
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          return _this.aris.login(void 0, void 0, function() {
            _this.siftr_url = 'snowchallenge';
            return _this.getGameInfo(function() {
              return _this.getGameOwners(function() {
                _this.createMap();
                return _this.getGameTags(function() {
                  _this.makeSearchTags();
                  return _this.performSearch(function() {
                    return _this.installListeners();
                  });
                });
              });
            });
          });
        };
      })(this));
    }

    App.prototype.getGameInfo = function(cb) {
      return this.aris.call('games.searchSiftrs', {
        siftr_url: this.siftr_url
      }, (function(_this) {
        return function(arg) {
          var games, returnCode;
          games = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0 && games.length === 1) {
            _this.game = new Game(games[0]);
            $('#the-siftr-title').text(_this.game.name);
            $('#the-siftr-subtitle').text('Started by Wilhuff Tarkin');
            return cb();
          } else {
            return _this.error("Failed to retrieve the Siftr game info");
          }
        };
      })(this));
    };

    App.prototype.getGameOwners = function(cb) {
      return this.aris.call('users.getUsersForGame', {
        game_id: this.game.game_id
      }, (function(_this) {
        return function(arg) {
          var o, owners, returnCode;
          owners = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0) {
            _this.game.owners = (function() {
              var i, len, results;
              results = [];
              for (i = 0, len = owners.length; i < len; i++) {
                o = owners[i];
                results.push(new User(o));
              }
              return results;
            })();
          } else {
            _this.game.owners = [];
            _this.warn("Failed to retrieve the list of Siftr owners");
          }
          return cb();
        };
      })(this));
    };

    App.prototype.createMap = function() {
      var opts;
      opts = {
        zoom: this.game.zoom,
        center: new google.maps.LatLng(this.game.latitude, this.game.longitude),
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        panControl: false,
        zoomControl: false,
        mapTypeControl: false,
        scaleControl: false,
        streetViewControl: false,
        overviewMapControl: false,
        styles: window.mapStyle.concat([
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [
              {
                visibility: 'off'
              }
            ]
          }
        ])
      };
      return this.map = new google.maps.Map($('#the-map')[0], opts);
    };

    App.prototype.getGameTags = function(cb) {
      return this.aris.call('tags.getTagsForGame', {
        game_id: this.game.game_id
      }, (function(_this) {
        return function(arg) {
          var o, returnCode, tags;
          tags = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0) {
            _this.game.tags = (function() {
              var i, len, results;
              results = [];
              for (i = 0, len = tags.length; i < len; i++) {
                o = tags[i];
                results.push(new Tag(o));
              }
              return results;
            })();
            return cb();
          } else {
            return _this.error("Failed to retrieve the list of tags");
          }
        };
      })(this));
    };

    App.prototype.makeSearchTags = function() {
      return appendTo($('#the-search-tags'), 'form', {}, (function(_this) {
        return function(form) {
          var i, len, ref, results, t;
          ref = _this.game.tags;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            t = ref[i];
            results.push(appendTo(form, 'p', {}, function(p) {
              return appendTo(p, 'label', {}, function(label) {
                appendTo(label, 'input', {
                  type: 'checkbox',
                  checked: false
                });
                return label.append(document.createTextNode(t.tag));
              });
            }));
          }
          return results;
        };
      })(this));
    };

    App.prototype.performSearch = function(cb) {
      return this.aris.call('notes.searchNotes', {
        game_id: this.game.game_id
      }, (function(_this) {
        return function(arg) {
          var notes, o, returnCode;
          notes = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0) {
            _this.game.notes = (function() {
              var i, len, results;
              results = [];
              for (i = 0, len = notes.length; i < len; i++) {
                o = notes[i];
                results.push(new Note(o));
              }
              return results;
            })();
            return _this.updateGrid(cb);
          } else {
            return _this.error("Failed to search for notes");
          }
        };
      })(this));
    };

    App.prototype.updateGrid = function(cb) {
      var i, len, note, ref;
      $('#the-note-grid').html('');
      ref = this.game.notes;
      for (i = 0, len = ref.length; i < len; i++) {
        note = ref[i];
        appendTo($('#the-note-grid'), 'p', {
          text: note.description
        });
      }
      return cb();
    };

    App.prototype.installListeners = function() {
      $('#the-user-logo, #the-menu-button').click((function(_this) {
        return function() {
          return $('body').toggleClass('is-mode-menu');
        };
      })(this));
      $('#the-add-button').click((function(_this) {
        return function() {
          return $('body').toggleClass('is-mode-add');
        };
      })(this));
      $('#the-icon-bar-x').click((function(_this) {
        return function() {
          $('body').removeClass('is-mode-add');
          return $('body').removeClass('is-mode-note');
        };
      })(this));
      if (this.aris.auth != null) {
        $('body').addClass('is-logged-in');
      }
      $('#the-logout-button').click((function(_this) {
        return function() {
          return _this.logout();
        };
      })(this));
      return $('#the-tag-button').click((function(_this) {
        return function() {
          return $('body').toggleClass('is-mode-tags');
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.aris.logout();
      return $('body').removeClass('is-logged-in');
    };

    App.prototype.error = function(s) {
      return console.log("ERROR: " + s);
    };

    App.prototype.warn = function(s) {
      return console.log("Warning: " + s);
    };

    return App;

  })();

  app = new App;

  window.app = app;

}).call(this);
