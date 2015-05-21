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
      this.photo_url = parseInt(json.media.data.media_id) === 0 ? null : json.media.data.url;
      this.latitude = parseFloat(json.latitude);
      this.longitude = parseFloat(json.longitude);
      this.tag_id = parseInt(json.tag_id);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.player_liked = parseInt(json.player_liked) !== 0;
      this.note_likes = parseInt(json.note_likes);
      this.comments = (function() {
        var j, len, ref, results;
        ref = json.comments.data;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          o = ref[j];
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
          var commaList, names, o, owners, returnCode, user;
          owners = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0) {
            _this.game.owners = (function() {
              var j, len, results;
              results = [];
              for (j = 0, len = owners.length; j < len; j++) {
                o = owners[j];
                results.push(new User(o));
              }
              return results;
            })();
            if (_this.game.owners.length > 0) {
              names = (function() {
                var j, len, ref, results;
                ref = this.game.owners;
                results = [];
                for (j = 0, len = ref.length; j < len; j++) {
                  user = ref[j];
                  results.push(user.display_name);
                }
                return results;
              }).call(_this);
              commaList = function(list) {
                switch (list.length) {
                  case 0:
                    return "";
                  case 1:
                    return list[0];
                  default:
                    return (list.slice(0, -1).join(', ')) + " and " + list[list.length - 1];
                }
              };
              $('#the-siftr-subtitle').text("Started by " + (commaList(names)));
            }
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
              var j, len, results;
              results = [];
              for (j = 0, len = tags.length; j < len; j++) {
                o = tags[j];
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
          var j, len, ref, results, t;
          ref = _this.game.tags;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            t = ref[j];
            results.push(appendTo(form, 'p', {}, function(p) {
              return appendTo(p, 'label', {}, function(label) {
                appendTo(label, 'input', {
                  type: 'checkbox',
                  checked: false,
                  value: t.tag_id
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
      var box, tag_ids, thisSearch;
      thisSearch = this.lastSearch = Date.now();
      tag_ids = (function() {
        var j, len, ref, results;
        ref = $('#the-search-tags input[type="checkbox"]');
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          box = ref[j];
          if (!box.checked) {
            continue;
          }
          results.push(parseInt(box.value));
        }
        return results;
      })();
      return this.aris.call('notes.searchNotes', {
        game_id: this.game.game_id,
        tag_ids: tag_ids
      }, (function(_this) {
        return function(arg) {
          var notes, o, returnCode;
          notes = arg.data, returnCode = arg.returnCode;
          if (returnCode === 0) {
            if (thisSearch === _this.lastSearch) {
              _this.game.notes = (function() {
                var j, len, results;
                results = [];
                for (j = 0, len = notes.length; j < len; j++) {
                  o = notes[j];
                  results.push(new Note(o));
                }
                return results;
              })();
              _this.updateGrid();
              _this.updateMap();
            }
            return cb();
          } else {
            return _this.error("Failed to search for notes");
          }
        };
      })(this));
    };

    App.prototype.updateGrid = function() {
      var grid, i, j, len, note, ref, results, tr;
      $('#the-note-grid').html('');
      grid = $('#the-note-grid');
      tr = null;
      ref = this.game.notes;
      results = [];
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        note = ref[i];
        results.push((function(_this) {
          return function(note) {
            var td;
            if (i % 3 === 0) {
              tr = appendTo(grid, '.a-grid-row');
            }
            td = appendTo(tr, '.a-grid-photo', {
              style: note.photo_url != null ? "background-image: url(\"" + note.photo_url + "\");" : "background-color: black;",
              alt: note.description
            });
            return td.click(function() {
              return _this.showNote(note);
            });
          };
        })(this)(note));
      }
      return results;
    };

    App.prototype.updateMap = function() {
      var j, len, marker, note, ref;
      if (this.markers != null) {
        ref = this.markers;
        for (j = 0, len = ref.length; j < len; j++) {
          marker = ref[j];
          marker.setMap(null);
        }
      }
      return this.markers = (function() {
        var k, len1, ref1, results;
        ref1 = this.game.notes;
        results = [];
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          note = ref1[k];
          results.push((function(_this) {
            return function(note) {
              marker = new google.maps.Marker({
                position: new google.maps.LatLng(note.latitude, note.longitude),
                map: _this.map
              });
              google.maps.event.addListener(marker, 'click', function() {
                return _this.showNote(note);
              });
              note.marker = marker;
              return marker;
            };
          })(this)(note));
        }
        return results;
      }).call(this);
    };

    App.prototype.showNote = function(note) {
      var comment, j, len, ref, results;
      $('body').removeClass('is-mode-add');
      $('body').removeClass('is-open-menu');
      $('body').addClass('is-mode-note');
      $('#the-photo').css('background-image', note.photo_url != null ? "url(\"" + note.photo_url + "\")" : '');
      $('#the-photo-caption').text(note.description);
      $('#the-photo-credit').html("Created by <b>" + (escapeHTML(note.user.display_name)) + "</b> at " + (escapeHTML(note.created.toLocaleString())));
      $('#the-comments').html('');
      if (note.comments.length > 0) {
        appendTo($('#the-comments'), 'h3', {
          text: 'Comments'
        });
        ref = note.comments;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          comment = ref[j];
          if (comment.description.match(/\S/)) {
            results.push(appendTo($('#the-comments'), 'div', {}, (function(_this) {
              return function(div) {
                appendTo(div, 'h4', {
                  text: comment.user.display_name + " (" + (comment.created.toLocaleString()) + ")"
                });
                return appendTo(div, 'p', {
                  text: comment.description
                });
              };
            })(this)));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };

    App.prototype.installListeners = function() {
      var body;
      body = $('body');
      $('#the-user-logo, #the-menu-button').click((function(_this) {
        return function() {
          return body.toggleClass('is-open-menu');
        };
      })(this));
      $('#the-grid-button').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          return body.removeClass('is-mode-map');
        };
      })(this));
      $('#the-map-button').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          return body.addClass('is-mode-map');
        };
      })(this));
      $('#the-add-button').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          body.toggleClass('is-mode-add');
          return body.removeClass('is-mode-map');
        };
      })(this));
      $('#the-icon-bar-x').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          return body.removeClass('is-mode-add');
        };
      })(this));
      if (this.aris.auth != null) {
        body.addClass('is-logged-in');
      }
      $('#the-logout-button').click((function(_this) {
        return function() {
          return _this.logout();
        };
      })(this));
      $('#the-tag-button').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          body.removeClass('is-mode-map');
          return body.toggleClass('is-open-tags');
        };
      })(this));
      return $('#the-search-tags input[type="checkbox"]').change((function(_this) {
        return function() {
          return _this.performSearch(function() {});
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
