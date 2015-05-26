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
      this.display_name = json.display_name || json.user_name;
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
      return this.map = new google.maps.Map($('#the-map')[0], {
        zoom: this.game.zoom,
        center: new google.maps.LatLng(this.game.latitude, this.game.longitude),
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        panControl: false,
        zoomControl: false,
        mapTypeControl: false,
        scaleControl: false,
        streetViewControl: false,
        overviewMapControl: false,
        styles: (function(_this) {
          return function() {
            var styles;
            styles = window.mapStyle;
            styles.push({
              featureType: 'poi',
              elementType: 'labels',
              stylers: [
                {
                  visibility: 'off'
                }
              ]
            });
            return styles;
          };
        })(this)()
      });
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
        tag_ids: tag_ids,
        order_by: 'recent'
      }, (function(_this) {
        return function(arg) {
          var n, notes, o, returnCode;
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
              _this.game.notes = (function() {
                var j, len, ref, results;
                ref = this.game.notes;
                results = [];
                for (j = 0, len = ref.length; j < len; j++) {
                  n = ref[j];
                  if (n.photo_url != null) {
                    results.push(n);
                  }
                }
                return results;
              }).call(_this);
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
      var comment, j, len, ref;
      this.scrollBackTo = $('#the-modal-content').scrollTop();
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
        for (j = 0, len = ref.length; j < len; j++) {
          comment = ref[j];
          if (comment.description.match(/\S/)) {
            appendTo($('#the-comments'), 'div', {}, (function(_this) {
              return function(div) {
                appendTo(div, 'h4', {
                  text: comment.user.display_name + " (" + (comment.created.toLocaleString()) + ")"
                });
                return appendTo(div, 'p', {
                  text: comment.description
                });
              };
            })(this));
          }
        }
      }
      return $('#the-modal-content').scrollTop(0);
    };

    App.prototype.installListeners = function() {
      var action, body, j, len, ref;
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
          body.removeClass('is-mode-map');
          if (_this.scrollBackTo != null) {
            $('#the-modal-content').scrollTop(_this.scrollBackTo);
            return delete _this.scrollBackTo;
          }
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
          body.removeClass('is-mode-map');
          return _this.readyFile(null);
        };
      })(this));
      $('#the-icon-bar-x').click((function(_this) {
        return function() {
          body.removeClass('is-open-menu');
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          if (_this.scrollBackTo != null) {
            $('#the-modal-content').scrollTop(_this.scrollBackTo);
            return delete _this.scrollBackTo;
          }
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
      $('#the-search-tags input[type="checkbox"]').change((function(_this) {
        return function() {
          return _this.performSearch(function() {});
        };
      })(this));
      $('#the-login-button').click((function(_this) {
        return function() {
          var n, p;
          if ((n = prompt('username')) != null) {
            if ((p = prompt('password')) != null) {
              return _this.login(n, p, function() {
                return _this.performSearch(function() {});
              });
            }
          }
        };
      })(this));
      ref = ['dragover', 'dragenter'];
      for (j = 0, len = ref.length; j < len; j++) {
        action = ref[j];
        $('#the-photo-upload-box').on(action, (function(_this) {
          return function(e) {
            e.preventDefault();
            return e.stopPropagation();
          };
        })(this));
      }
      $('#the-photo-upload-box').on('drop', (function(_this) {
        return function(e) {
          var xfer;
          if (xfer = e.originalEvent.dataTransfer) {
            if (xfer.files.length) {
              e.preventDefault();
              e.stopPropagation();
              return _this.readyFile(xfer.files[0]);
            }
          }
        };
      })(this));
      $('#the-photo-upload-box').click((function(_this) {
        return function() {
          return $('#the-hidden-file-input').click();
        };
      })(this));
      return $('#the-hidden-file-input').on('change', (function(_this) {
        return function() {
          return _this.readyFile($('#the-hidden-file-input')[0].files[0]);
        };
      })(this));
    };

    App.prototype.readyFile = function(file) {
      var reader;
      if (file != null) {
        reader = new FileReader();
        reader.onload = (function(_this) {
          return function(e) {
            var dataURL, ext, mime, prefix, typeMap;
            dataURL = e.target.result;
            typeMap = {
              jpg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif'
            };
            for (ext in typeMap) {
              mime = typeMap[ext];
              prefix = "data:" + mime + ";base64,";
              if (dataURL.substring(0, prefix.length) === prefix) {
                _this.ext = ext;
                _this.base64 = dataURL.substring(prefix.length);
                break;
              }
            }
            return $('#the-photo-upload-box').css('background-image', "url(\"" + dataURL + "\")");
          };
        })(this);
        return reader.readAsDataURL(file);
      } else {
        delete this.ext;
        delete this.base64;
        return $('#the-photo-upload-box').css('background-image', '');
      }
    };

    App.prototype.login = function(name, pw, cb) {
      return this.aris.login(name, pw, (function(_this) {
        return function() {
          if (_this.aris.auth != null) {
            $('body').addClass('is-logged-in');
          } else {
            $('body').removeClass('is-logged-in');
          }
          return cb();
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
