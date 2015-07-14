(function() {
  var App, app,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  App = (function() {
    function App() {
      $(function() {
        return FastClick.attach(document.body);
      });
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          cordovaFixLinks();
          _this.markdown = new Showdown.converter();
          return _this.login(void 0, void 0, function() {
            _this.siftr_url = window.location.search.replace('?', '');
            if (_this.siftr_url.length === 0) {
              _this.siftr_url = window.location.pathname.replace(/\//g, '');
            }
            if (!_this.siftr_url.match(/[^0-9]/)) {
              _this.siftr_id = parseInt(_this.siftr_url);
              _this.siftr_url = null;
            }
            return _this.getGameInfo(function() {
              return _this.getGameOwners(function() {
                _this.createMap();
                return _this.getGameTags(function() {
                  _this.makeTagLists();
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
      var useGame;
      useGame = (function(_this) {
        return function(game) {
          _this.game = game;
          $('#the-siftr-title').text(_this.game.name);
          return cb();
        };
      })(this);
      if (this.siftr_url != null) {
        return this.aris.call('games.searchSiftrs', {
          siftr_url: this.siftr_url
        }, (function(_this) {
          return function(_arg) {
            var games, returnCode;
            games = _arg.data, returnCode = _arg.returnCode;
            if (returnCode === 0 && games.length === 1) {
              return useGame(new Game(games[0]));
            } else {
              return _this.error("Couldn't find a Siftr with the URL " + _this.siftr_url);
            }
          };
        })(this));
      } else if (this.siftr_id != null) {
        return this.aris.call('games.getGame', {
          game_id: this.siftr_id
        }, (function(_this) {
          return function(_arg) {
            var game, returnCode;
            game = _arg.data, returnCode = _arg.returnCode;
            if (returnCode === 0 && (game != null)) {
              return useGame(new Game(game));
            } else {
              return _this.error("Couldn't find a Siftr with game ID " + _this.siftr_id);
            }
          };
        })(this));
      } else {
        return this.error("No Siftr specified");
      }
    };

    App.prototype.getGameOwners = function(cb) {
      return this.aris.call('users.getUsersForGame', {
        game_id: this.game.game_id
      }, (function(_this) {
        return function(_arg) {
          var commaList, names, o, owners, returnCode, user;
          owners = _arg.data, returnCode = _arg.returnCode;
          if (returnCode === 0) {
            _this.game.owners = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = owners.length; _i < _len; _i++) {
                o = owners[_i];
                _results.push(new User(o));
              }
              return _results;
            })();
            _this.checkIfOwner();
            if (_this.game.owners.length > 0) {
              names = (function() {
                var _i, _len, _ref, _results;
                _ref = this.game.owners;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  user = _ref[_i];
                  _results.push(user.display_name);
                }
                return _results;
              }).call(_this);
              commaList = function(list) {
                switch (list.length) {
                  case 0:
                    return "";
                  case 1:
                    return list[0];
                  default:
                    return "" + (list.slice(0, -1).join(', ')) + " and " + list[list.length - 1];
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

    App.prototype.centerMapOffset = function(latlng, offsetx, offsety) {
      var p1, p2, z;
      if (latlng == null) {
        latlng = this.map.getCenter();
      }
      if (offsetx == null) {
        offsetx = 0;
      }
      if (offsety == null) {
        offsety = 0;
      }
      p1 = this.map.getProjection().fromLatLngToPoint(latlng);
      z = this.map.getZoom();
      p2 = new google.maps.Point(offsetx / (Math.pow(2, z)), offsety / (Math.pow(2, z)));
      return this.map.setCenter((function(_this) {
        return function() {
          return _this.map.getProjection().fromPointToLatLng((function() {
            return new google.maps.Point(p1.x - p2.x, p1.y - p2.y);
          })());
        };
      })(this)());
    };

    App.prototype.setMapCenter = function(latlng) {
      var listener, offsetx, w;
      w = $('body').width();
      if (w < 907) {
        return this.map.setCenter(latlng);
      } else {
        offsetx = $('#the-main-modal').offset().left / 2 - w / 2;
        if (this.map.getProjection() != null) {
          return this.centerMapOffset(latlng, offsetx, 0);
        } else {
          return listener = google.maps.event.addListener(this.map, 'projection_changed', (function(_this) {
            return function() {
              if (_this.map.getProjection() != null) {
                _this.centerMapOffset(latlng, offsetx, 0);
                return google.maps.event.removeListener(listener);
              }
            };
          })(this));
        }
      }
    };

    App.prototype.createMap = function() {
      this.mapCenter = new google.maps.LatLng(this.game.latitude, this.game.longitude);
      this.map = new google.maps.Map($('#the-map')[0], {
        zoom: this.game.zoom,
        center: this.mapCenter,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        panControl: false,
        zoomControl: false,
        mapTypeControl: false,
        scaleControl: false,
        streetViewControl: false,
        overviewMapControl: false,
        styles: window.mapStyle.concat({
          featureType: 'poi',
          elementType: 'labels',
          stylers: [
            {
              visibility: 'off'
            }
          ]
        })
      });
      this.setMapCenter(this.mapCenter);
      return this.dragMarker = new google.maps.Marker({
        position: this.mapCenter,
        map: null,
        draggable: true,
        zIndexProcess: function() {
          return 9999;
        }
      });
    };

    App.prototype.getGameTags = function(cb) {
      return this.aris.call('tags.getTagsForGame', {
        game_id: this.game.game_id
      }, (function(_this) {
        return function(_arg) {
          var o, returnCode, tags;
          tags = _arg.data, returnCode = _arg.returnCode;
          if (returnCode === 0) {
            _this.game.tags = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = tags.length; _i < _len; _i++) {
                o = tags[_i];
                _results.push(new Tag(o));
              }
              return _results;
            })();
            return cb();
          } else {
            return _this.error("Failed to retrieve the list of tags");
          }
        };
      })(this));
    };

    App.prototype.makeTagLists = function() {
      appendTo($('#the-search-tags'), 'form', {}, (function(_this) {
        return function(form) {
          var t, _i, _len, _ref, _results;
          _ref = _this.game.tags;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            t = _ref[_i];
            _results.push(appendTo(form, 'p', {}, function(p) {
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
          return _results;
        };
      })(this));
      return appendTo($('#the-tag-assigner, #the-editor-tag-assigner'), 'form', {}, (function(_this) {
        return function(form) {
          var i, t, _i, _len, _ref, _results;
          _ref = _this.game.tags;
          _results = [];
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            t = _ref[i];
            _results.push(appendTo(form, 'p', {}, function(p) {
              return appendTo(p, 'label', {}, function(label) {
                appendTo(label, 'input', {
                  type: 'radio',
                  checked: i === 0,
                  name: 'upload-tag',
                  value: t.tag_id
                });
                return label.append(document.createTextNode(t.tag));
              });
            }));
          }
          return _results;
        };
      })(this));
    };

    App.prototype.performSearch = function(cb) {
      var box, tag_ids, thisSearch;
      thisSearch = this.lastSearch = Date.now();
      tag_ids = (function() {
        var _i, _len, _ref, _results;
        _ref = $('#the-search-tags input[type="checkbox"]');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          box = _ref[_i];
          if (!box.checked) {
            continue;
          }
          _results.push(parseInt(box.value));
        }
        return _results;
      })();
      return this.aris.call('notes.searchNotes', {
        game_id: this.game.game_id,
        tag_ids: tag_ids,
        order_by: 'recent'
      }, (function(_this) {
        return function(_arg) {
          var n, notes, o, returnCode;
          notes = _arg.data, returnCode = _arg.returnCode;
          if (returnCode === 0) {
            if (thisSearch === _this.lastSearch) {
              _this.game.notes = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = notes.length; _i < _len; _i++) {
                  o = notes[_i];
                  _results.push(new Note(o));
                }
                return _results;
              })();
              _this.game.notes = (function() {
                var _i, _len, _ref, _results;
                _ref = this.game.notes;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  n = _ref[_i];
                  if (n.photo_url != null) {
                    _results.push(n);
                  }
                }
                return _results;
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
      var grid, i, note, tr, _i, _len, _ref, _results;
      $('#the-note-grid').html('');
      grid = $('#the-note-grid');
      tr = null;
      _ref = this.game.notes;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        note = _ref[i];
        _results.push((function(_this) {
          return function(note) {
            var td;
            if (i % 3 === 0) {
              tr = appendTo(grid, '.a-grid-row');
            }
            td = appendTo(tr, '.a-grid-photo', {
              style: note.thumb_url != null ? "background-image: url(\"" + note.thumb_url + "\");" : "background-color: black;",
              alt: note.description
            });
            return td.click(function() {
              return _this.showNote(note);
            });
          };
        })(this)(note));
      }
      return _results;
    };

    App.prototype.updateMap = function() {
      var note;
      if (this.clusterer != null) {
        this.clusterer.clearMarkers();
      }
      return this.clusterer = new MarkerClusterer(this.map, (function() {
        var _i, _len, _ref, _results;
        _ref = this.game.notes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          note = _ref[_i];
          _results.push((function(_this) {
            return function(note) {
              var marker;
              marker = new google.maps.Marker({
                position: new google.maps.LatLng(note.latitude, note.longitude)
              });
              google.maps.event.addListener(marker, 'click', function() {
                return _this.showNote(note);
              });
              note.marker = marker;
              return marker;
            };
          })(this)(note));
        }
        return _results;
      }).call(this), {
        maxZoom: 18
      });
    };

    App.prototype.showNote = function(note) {
      var canDelete, canEdit, canFlag, comment, commentIndex, heart, markdown, _i, _len, _ref, _ref1, _ref2, _results;
      if (window.location.hash !== '#' + note.note_id) {
        history.pushState('', '', '#' + note.note_id);
      }
      this.currentNote = note;
      this.scrollBackTo = $('#the-modal-content').scrollTop();
      this.setMode('note');
      $('#the-modal-content').scrollTop(0);
      $('#the-photo').css('background-image', note.photo_url != null ? "url(\"" + note.photo_url + "\")" : '');
      if (typeof cordova !== "undefined" && cordova !== null) {
        $('#the-photo-link').off('click');
        $('#the-photo-link').click((function(_this) {
          return function() {
            return window.open(note.photo_url, '_system');
          };
        })(this));
      } else {
        $('#the-photo-link').prop('href', note.photo_url);
      }
      markdown = this.markdown.makeHtml(note.description);
      markdown = markdown.replace(/<script[^>]*?>.*?<\/script>/gi, '').replace(/<style[^>]*?>.*?<\/style>/gi, '').replace(/<![\s\S]*?--[ \t\n\r]*>/gi, '');
      $('#the-photo-caption').html(markdown);
      $('#the-photo-credit').html("Created by <b>" + (escapeHTML(note.user.display_name)) + "</b> at " + (escapeHTML(note.created.toLocaleString())));
      heart = $('#the-like-button i');
      if (note.player_liked) {
        heart.addClass('fa-heart');
        heart.removeClass('fa-heart-o');
      } else {
        heart.addClass('fa-heart-o');
        heart.removeClass('fa-heart');
      }
      canEdit = ((_ref = this.aris.auth) != null ? _ref.user_id : void 0) === note.user.user_id;
      canDelete = canEdit || this.userIsOwner;
      $('#the-edit-button').toggle(canEdit || canDelete);
      $('#the-start-edit-button').toggle(canEdit);
      $('#the-delete-button').toggle(canDelete);
      canFlag = note.published === 'AUTO' && ((_ref1 = this.aris.auth) != null ? _ref1.user_id : void 0) !== note.user.user_id;
      $('#the-flag-button').toggle(canFlag);
      $('#the-comments').html('');
      if (note.comments.length > 0) {
        appendTo($('#the-comments'), 'h3', {
          text: 'Comments'
        });
        _ref2 = note.comments;
        _results = [];
        for (commentIndex = _i = 0, _len = _ref2.length; _i < _len; commentIndex = ++_i) {
          comment = _ref2[commentIndex];
          _results.push((function(_this) {
            return function(comment, commentIndex) {
              return appendTo($('#the-comments'), 'div', {}, function(div) {
                var desc, editPencil, editing, _ref3;
                canEdit = ((_ref3 = _this.aris.auth) != null ? _ref3.user_id : void 0) === comment.user.user_id;
                canDelete = canEdit || _this.userIsOwner;
                editPencil = null;
                appendTo(div, 'h4', {}, function(h4) {
                  appendTo(h4, 'span', {
                    text: "" + comment.user.display_name + " (" + (comment.created.toLocaleString()) + ")"
                  });
                  if (canEdit) {
                    editPencil = appendTo(h4, 'i.fa.fa-pencil', {
                      style: 'cursor: pointer; margin: 3px;'
                    });
                  }
                  if (canDelete) {
                    return appendTo(h4, 'i.fa.fa-trash', {
                      style: 'cursor: pointer; margin: 3px;',
                      click: function() {
                        if (confirm('Are you sure you want to delete this comment?')) {
                          return _this.aris.call('note_comments.deleteNoteComment', {
                            note_comment_id: comment.comment_id
                          }, function(_arg) {
                            var returnCode;
                            returnCode = _arg.returnCode;
                            if (returnCode === 0) {
                              note.comments.splice(commentIndex, 1);
                              return _this.showNote(note);
                            } else {
                              return _this.error("There was a problem deleting that comment.");
                            }
                          });
                        }
                      }
                    });
                  }
                });
                desc = appendTo(div, 'p', {
                  text: comment.description
                });
                if (editPencil != null) {
                  editing = false;
                  return editPencil.click(function() {
                    if (!editing) {
                      editing = true;
                      desc.hide();
                      return appendTo(div, 'div', {}, function(editStuff) {
                        var editBox;
                        editBox = appendTo(editStuff, 'textarea', {
                          placeholder: 'Edit your comment',
                          val: comment.description,
                          style: 'resize: none; width: 100%; margin-bottom: 10px;'
                        });
                        appendTo(editStuff, 'button', {
                          type: 'button',
                          text: 'Save changes',
                          click: function() {
                            return _this.aris.call('note_comments.updateNoteComment', {
                              note_comment_id: comment.comment_id,
                              description: editBox.val()
                            }, function(_arg) {
                              var json, returnCode;
                              json = _arg.data, returnCode = _arg.returnCode;
                              if (returnCode !== 0) {
                                _this.error("There was a problem posting your comment.");
                                return;
                              }
                              editing = false;
                              editStuff.remove();
                              desc.show();
                              _this.currentNote.comments[commentIndex] = new Comment(json);
                              return _this.showNote(_this.currentNote);
                            });
                          }
                        });
                        return appendTo(editStuff, 'button', {
                          type: 'button',
                          text: 'Cancel',
                          click: function() {
                            editing = false;
                            editStuff.remove();
                            return desc.show();
                          }
                        });
                      });
                    }
                  });
                }
              });
            };
          })(this)(comment, commentIndex));
        }
        return _results;
      }
    };

    App.prototype.setMode = function(mode) {
      var body, oldMode, _ref, _ref1;
      if (mode !== 'note' && ((_ref = window.location.hash) !== '#' && _ref !== '')) {
        history.pushState('', '', '#');
      }
      body = $('body');
      oldMode = this.mode;
      this.mode = mode;
      body.removeClass('is-open-menu');
      body.removeClass('is-open-share');
      body.removeClass('is-open-edit');
      this.dragMarker.setMap(null);
      switch (mode) {
        case 'grid':
          this.topMode = 'grid';
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          body.removeClass('is-mode-edit');
          body.removeClass('is-mode-map');
          if (this.scrollBackTo != null) {
            $('#the-modal-content').scrollTop(this.scrollBackTo);
            return delete this.scrollBackTo;
          }
          break;
        case 'map':
          this.topMode = 'map';
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          body.removeClass('is-mode-edit');
          return body.addClass('is-mode-map');
        case 'note':
          body.addClass('is-mode-note');
          body.removeClass('is-mode-add');
          body.removeClass('is-mode-edit');
          return body.removeClass('is-mode-map');
        case 'add':
          body.removeClass('is-mode-note');
          body.addClass('is-mode-add');
          body.removeClass('is-mode-edit');
          body.removeClass('is-mode-map');
          this.dragMarker.setMap(this.map);
          this.dragMarker.setPosition(this.mapCenter);
          this.dragMarker.setAnimation(google.maps.Animation.DROP);
          this.map.setZoom(this.game.zoom);
          this.setMapCenter(this.mapCenter);
          if ((_ref1 = this.clusterer) != null) {
            _ref1.repaint();
          }
          $('#the-caption-box').val('');
          return $('#the-tag-assigner input[name=upload-tag]:first').click();
        case 'edit':
          body.removeClass('is-mode-note');
          body.removeClass('is-mode-add');
          body.addClass('is-mode-edit');
          return body.removeClass('is-mode-map');
      }
    };

    App.prototype.startEdit = function(note) {
      var position, radio, _i, _len, _ref, _ref1;
      this.setMode('edit');
      this.currentNote = note;
      position = new google.maps.LatLng(note.latitude, note.longitude);
      this.dragMarker.setMap(this.map);
      this.dragMarker.setPosition(position);
      this.dragMarker.setAnimation(google.maps.Animation.DROP);
      this.map.setZoom(this.game.zoom);
      this.setMapCenter(position);
      if ((_ref = this.clusterer) != null) {
        _ref.repaint();
      }
      $('#the-editor-caption-box').val(note.description);
      _ref1 = $('#the-editor-tag-assigner input[name=upload-tag]');
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        radio = _ref1[_i];
        radio = $(radio);
        if (note.tag_id === parseInt(radio.val())) {
          radio.click();
        }
      }
      return $('#the-editor-photo-box').css('background-image', "url(\"" + note.photo_url + "\")");
    };

    App.prototype.submitEdit = function() {
      var desc;
      desc = $('#the-editor-caption-box').val();
      if (desc.length === 0) {
        this.error('Please enter a caption for the image.');
        return;
      }
      return this.aris.call('notes.updateNote', {
        game_id: this.game.game_id,
        note_id: this.currentNote.note_id,
        description: desc,
        trigger: {
          latitude: this.dragMarker.getPosition().lat(),
          longitude: this.dragMarker.getPosition().lng()
        },
        tag_id: parseInt($('#the-editor-tag-assigner input[name=upload-tag]:checked').val())
      }, (function(_this) {
        return function(_arg) {
          var returnCode;
          returnCode = _arg.returnCode;
          if (returnCode !== 0) {
            _this.error("There was a problem submitting your changes.");
            return;
          }
          return _this.aris.call('notes.searchNotes', {
            game_id: _this.game.game_id,
            note_id: _this.currentNote.note_id,
            note_count: 1
          }, function(_arg1) {
            var existingNote, newNote, noteIndex, notes, returnCode, _i, _len, _ref;
            notes = _arg1.data, returnCode = _arg1.returnCode;
            if (returnCode !== 0 || notes.length !== 1) {
              _this.error('There was an error retrieving your edited note.');
              return;
            }
            newNote = new Note(notes[0]);
            _ref = _this.game.notes;
            for (noteIndex = _i = 0, _len = _ref.length; _i < _len; noteIndex = ++_i) {
              existingNote = _ref[noteIndex];
              if (existingNote.note_id === newNote.note_id) {
                _this.game.notes[noteIndex] = newNote;
                break;
              }
            }
            _this.updateGrid();
            _this.updateMap();
            return _this.showNote(newNote);
          });
        };
      })(this));
    };

    App.prototype.submitNote = function() {
      var desc;
      if (!((this.ext != null) && (this.base64 != null))) {
        this.error('Please select a photo to upload.');
        return;
      }
      desc = $('#the-caption-box').val();
      if (desc.length === 0) {
        this.error('Please enter a caption for the image.');
        return;
      }
      return this.aris.call('notes.createNote', {
        game_id: this.game.game_id,
        media: {
          file_name: "upload." + this.ext,
          data: this.base64,
          resize: 640
        },
        description: desc,
        trigger: {
          latitude: this.dragMarker.getPosition().lat(),
          longitude: this.dragMarker.getPosition().lng()
        },
        tag_id: parseInt($('#the-tag-assigner input[name=upload-tag]:checked').val())
      }, (function(_this) {
        return function(_arg) {
          var returnCode, simpleNote;
          simpleNote = _arg.data, returnCode = _arg.returnCode;
          if (returnCode !== 0) {
            _this.error('There was an error uploading your photo.');
            return;
          }
          return _this.aris.call('notes.searchNotes', {
            game_id: _this.game.game_id,
            note_id: parseInt(simpleNote.note_id),
            note_count: 1
          }, function(_arg1) {
            var note, notes, returnCode;
            notes = _arg1.data, returnCode = _arg1.returnCode;
            if (returnCode !== 0 || notes.length !== 1) {
              _this.error('There was an error retrieving your new photo.');
              return;
            }
            note = new Note(notes[0]);
            _this.game.notes.unshift(note);
            _this.updateGrid();
            _this.updateMap();
            return _this.showNote(note);
          });
        };
      })(this));
    };

    App.prototype.needsAuth = function(act) {
      if (this.aris.auth != null) {
        return act();
      } else {
        return $('body').addClass('is-open-menu');
      }
    };

    App.prototype.goToHash = function() {
      var md, note, note_id, _i, _len, _ref;
      if (md = window.location.hash.match(/^#(\d+)$/)) {
        note_id = parseInt(md[1]);
        _ref = this.game.notes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          note = _ref[_i];
          if (note.note_id === note_id) {
            this.showNote(note);
            return;
          }
        }
      }
      return this.setMode(this.topMode);
    };

    App.prototype.installListeners = function() {
      var body, currentNoteTag, currentNoteVerb;
      body = $('body');
      this.topMode = 'grid';
      this.goToHash();
      $(window).on('hashchange', (function(_this) {
        return function() {
          return _this.goToHash();
        };
      })(this));
      $('#the-user-logo, #the-menu-button').click((function(_this) {
        return function() {
          return body.toggleClass('is-open-menu');
        };
      })(this));
      $('#the-grid-button').click((function(_this) {
        return function() {
          return _this.setMode('grid');
        };
      })(this));
      $('#the-map-button').click((function(_this) {
        return function() {
          return _this.setMode('map');
        };
      })(this));
      $('#the-add-button, #the-mobile-add-button').click((function(_this) {
        return function() {
          if (_this.mode === 'add') {
            return _this.setMode(_this.topMode);
          } else {
            return _this.needsAuth(function() {
              _this.setMode('add');
              return _this.readyFile(null);
            });
          }
        };
      })(this));
      $('#the-icon-bar-x, #the-add-cancel-button').click((function(_this) {
        return function() {
          return _this.setMode(_this.topMode);
        };
      })(this));
      $('#the-logout-button').click((function(_this) {
        return function() {
          _this.logout();
          body.removeClass('is-open-menu');
          _this.setMode(_this.topMode);
          return _this.performSearch(function() {});
        };
      })(this));
      $('#the-tag-button').click((function(_this) {
        return function() {
          if (_this.mode === 'map') {
            body.addClass('is-open-tags');
          } else {
            body.toggleClass('is-open-tags');
          }
          _this.setMode('grid');
          return $('#the-modal-content').scrollTop(0);
        };
      })(this));
      $('#the-search-tags input[type="checkbox"]').change((function(_this) {
        return function() {
          return _this.performSearch(function() {});
        };
      })(this));
      $('#the-add-submit-button').click((function(_this) {
        return function() {
          return _this.submitNote();
        };
      })(this));
      $('#the-edit-submit-button').click((function(_this) {
        return function() {
          return _this.submitEdit();
        };
      })(this));
      $('#the-edit-cancel-button').click((function(_this) {
        return function() {
          return _this.showNote(_this.currentNote);
        };
      })(this));
      $('#the-share-button').click((function(_this) {
        return function() {
          body.toggleClass('is-open-share');
          return body.removeClass('is-open-edit');
        };
      })(this));
      $('#the-edit-button').click((function(_this) {
        return function() {
          body.toggleClass('is-open-edit');
          return body.removeClass('is-open-share');
        };
      })(this));
      $('#the-like-button').click((function(_this) {
        return function() {
          return _this.needsAuth(function() {
            var heart;
            heart = $('#the-like-button i');
            if (_this.currentNote.player_liked) {
              return _this.aris.call('notes.unlikeNote', {
                note_id: _this.currentNote.note_id
              }, function(_arg) {
                var returnCode;
                returnCode = _arg.returnCode;
                if (returnCode === 0) {
                  _this.currentNote.player_liked = false;
                  heart.addClass('fa-heart-o');
                  return heart.removeClass('fa-heart');
                } else {
                  return _this.error("There was a problem recording your unlike.");
                }
              });
            } else {
              return _this.aris.call('notes.likeNote', {
                note_id: _this.currentNote.note_id
              }, function(_arg) {
                var returnCode;
                returnCode = _arg.returnCode;
                if (returnCode === 0) {
                  _this.currentNote.player_liked = true;
                  heart.addClass('fa-heart');
                  return heart.removeClass('fa-heart-o');
                } else {
                  return _this.error("There was a problem recording your like.");
                }
              });
            }
          });
        };
      })(this));
      $('#the-flag-button').click((function(_this) {
        return function() {
          if (confirm('Are you sure you want to flag this note for inappropriate content?')) {
            return _this.aris.call('notes.flagNote', {
              note_id: _this.currentNote.note_id
            }, function(_arg) {
              var returnCode;
              returnCode = _arg.returnCode;
              if (returnCode === 0) {
                return _this.performSearch(function() {
                  return _this.setMode(_this.topMode);
                });
              } else {
                return _this.error("There was a problem recording your flag.");
              }
            });
          }
        };
      })(this));
      $('#the-start-edit-button').click((function(_this) {
        return function() {
          return _this.startEdit(_this.currentNote);
        };
      })(this));
      $('#the-delete-button').click((function(_this) {
        return function() {
          if (confirm('Are you sure you want to delete this note?')) {
            return _this.aris.call('notes.deleteNote', {
              note_id: _this.currentNote.note_id
            }, function(_arg) {
              var returnCode;
              returnCode = _arg.returnCode;
              if (returnCode === 0) {
                return _this.performSearch(function() {
                  return _this.setMode(_this.topMode);
                });
              } else {
                return _this.error("There was an error deleting that note.");
              }
            });
          }
        };
      })(this));
      currentNoteTag = (function(_this) {
        return function() {
          var tag, _i, _len, _ref;
          _ref = _this.game.tags;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            tag = _ref[_i];
            if (tag.tag_id === _this.currentNote.tag_id) {
              return tag.tag;
            }
          }
          return '???';
        };
      })(this);
      currentNoteVerb = (function(_this) {
        return function() {
          var _ref;
          if (_this.currentNote.user.user_id === ((_ref = app.aris.auth) != null ? _ref.user_id : void 0)) {
            return 'made';
          } else {
            return 'found';
          }
        };
      })(this);
      $('#the-email-button').click((function(_this) {
        return function() {
          var email, link, subject, tag;
          tag = currentNoteTag();
          subject = "Interesting note on " + tag;
          email = "Check out this note I " + (currentNoteVerb()) + " about " + tag + ":\n\n" + _this.currentNote.description + "\n\nSee the whole note at: " + window.location.href;
          link = "mailto:?subject=" + (encodeURIComponent(subject)) + "&body=" + (encodeURIComponent(email));
          return window.open(link);
        };
      })(this));
      $('#the-facebook-button').click((function(_this) {
        return function() {
          var link;
          link = "https://www.facebook.com/sharer/sharer.php?u=" + (encodeURIComponent(window.location.href));
          return window.open(link, '_system');
        };
      })(this));
      $('#the-google-button').click((function(_this) {
        return function() {
          var link;
          link = "https://plus.google.com/share?url=" + (encodeURIComponent(window.location.href));
          return window.open(link, '_system');
        };
      })(this));
      $('#the-twitter-button').click((function(_this) {
        return function() {
          var link, tweet;
          tweet = "Check out this note I " + (currentNoteVerb()) + " about " + (currentNoteTag()) + ":";
          link = "https://twitter.com/share?&url=" + (encodeURIComponent(window.location.href)) + "&text=" + (encodeURIComponent(tweet));
          return window.open(link, '_system');
        };
      })(this));
      $('#the-pinterest-button').click((function(_this) {
        return function() {
          var desc, link;
          desc = "Check out this note I " + (currentNoteVerb()) + " about " + (currentNoteTag()) + ".";
          link = "http://www.pinterest.com/pin/create/button/";
          link += "?url=" + (encodeURIComponent(window.location.href));
          link += "&media=" + (encodeURIComponent(app.currentNote.photo_url));
          link += "&description=" + (encodeURIComponent(desc));
          return window.open(link, '_system');
        };
      })(this));
      $('#the-login-button').click((function(_this) {
        return function() {
          return _this.login($('#the-username-input').val(), $('#the-password-input').val(), function() {
            if (_this.aris.auth != null) {
              body.removeClass('is-open-menu');
              return _this.performSearch(function() {
                var note, oldNoteID, _i, _len, _ref;
                if (body.hasClass('is-mode-note')) {
                  oldNoteID = _this.currentNote.note_id;
                  _this.currentNote = null;
                  _ref = _this.game.notes;
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    note = _ref[_i];
                    if (note.note_id === oldNoteID) {
                      _this.currentNote = note;
                      break;
                    }
                  }
                  if (_this.currentNote != null) {
                    return _this.showNote(_this.currentNote);
                  } else {
                    return _this.setMode(_this.topMode);
                  }
                }
              });
            }
          });
        };
      })(this));
      $('#the-username-input, #the-password-input').keypress((function(_this) {
        return function(e) {
          if (e.which === 13) {
            $('#the-login-button').click();
            return false;
          }
        };
      })(this));
      $('#the-photo-upload-box').on('dragover dragenter', (function(_this) {
        return function(e) {
          return false;
        };
      })(this));
      $('#the-photo-upload-box').on('drop', (function(_this) {
        return function(e) {
          var xfer;
          if (xfer = e.originalEvent.dataTransfer) {
            if (xfer.files.length) {
              _this.readyFile(xfer.files[0]);
              return false;
            }
          }
        };
      })(this));
      $('#the-photo-upload-box').click((function(_this) {
        return function() {
          return $('#the-hidden-file-input').click();
        };
      })(this));
      $('#the-hidden-file-input').on('change', (function(_this) {
        return function() {
          return _this.readyFile($('#the-hidden-file-input')[0].files[0]);
        };
      })(this));
      $('#the-comment-button').click((function(_this) {
        return function() {
          if ($('#the-comment-field').val().match(/\S/)) {
            return _this.needsAuth(function() {
              return _this.aris.call('note_comments.createNoteComment', {
                game_id: _this.game.game_id,
                note_id: _this.currentNote.note_id,
                description: $('#the-comment-field').val()
              }, function(_arg) {
                var json, returnCode;
                json = _arg.data, returnCode = _arg.returnCode;
                if (returnCode === 0) {
                  _this.currentNote.comments.push(new Comment(json));
                  return _this.showNote(_this.currentNote);
                } else {
                  return _this.error("There was a problem posting your comment.");
                }
              });
            });
          }
        };
      })(this));
      return window.FDL_CLUSTER_BOUNDS_EDITOR = (function(_this) {
        return function(bounds) {
          var east, north, south, w, west;
          w = $('body').width();
          if (w < 907) {
            return bounds;
          }
          north = bounds.getNorthEast().lat();
          south = bounds.getSouthWest().lat();
          east = bounds.getNorthEast().lng();
          west = bounds.getSouthWest().lng();
          console.log(east);
          east = west + (east - west) * w / $('#the-main-modal').offset().left;
          console.log(east);
          return new google.maps.LatLngBounds(new google.maps.LatLng(south, west), new google.maps.LatLng(north, east));
        };
      })(this);
    };

    App.prototype.readyFile = function(file) {
      var reader;
      delete this.ext;
      delete this.base64;
      $('#the-photo-upload-box').css('background-image', '');
      if (file != null) {
        reader = new FileReader();
        reader.onload = (function(_this) {
          return function(e) {
            var dataURL, ext, mime, prefix, typeMap, _results;
            dataURL = e.target.result;
            typeMap = {
              jpg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif'
            };
            _results = [];
            for (ext in typeMap) {
              mime = typeMap[ext];
              prefix = "data:" + mime + ";base64,";
              if (dataURL.substring(0, prefix.length) === prefix) {
                _this.ext = ext;
                _this.base64 = dataURL.substring(prefix.length);
                $('#the-photo-upload-box').css('background-image', "url(\"" + dataURL + "\")");
                break;
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
        })(this);
        return reader.readAsDataURL(file);
      }
    };

    App.prototype.login = function(name, pw, cb) {
      return this.aris.login(name, pw, (function(_this) {
        return function() {
          $('body').toggleClass('is-logged-in', _this.aris.auth != null);
          _this.checkIfOwner();
          if (_this.aris.auth != null) {
            $('#the-user-logo').css('background-image', 'url("img/user.png")');
            _this.aris.call('users.getUser', {
              user_id: _this.aris.auth.user_id
            }, function(_arg) {
              var user;
              user = _arg.data;
              if (user != null) {
                return _this.aris.call('media.getMedia', {
                  media_id: user.media_id
                }, function(_arg1) {
                  var media;
                  media = _arg1.data;
                  if (media != null) {
                    return $('#the-user-logo').css('background-image', "url(\"" + media.thumb_url + "\")");
                  }
                });
              }
            });
          }
          return cb();
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.aris.logout();
      this.checkIfOwner();
      $('body').removeClass('is-logged-in');
      $('body').removeClass('is-mode-add');
      return $('#the-user-logo').css('background-image', 'url("img/mystery.png")');
    };

    App.prototype.checkIfOwner = function() {
      var _ref, _ref1;
      return this.userIsOwner = (this.aris.auth != null) && (((_ref = this.game) != null ? _ref.owners : void 0) != null) && (_ref1 = this.aris.auth.user_id, __indexOf.call(this.game.owners.map((function(_this) {
        return function(user) {
          return user.user_id;
        };
      })(this)), _ref1) >= 0);
    };

    App.prototype.error = function(s) {
      console.log("ERROR: " + s);
      return alert("An error occurred: " + s);
    };

    App.prototype.warn = function(s) {
      return console.log("Warning: " + s);
    };

    return App;

  })();

  app = new App;

  window.app = app;

}).call(this);

(function() {
  window.Game = (function() {
    function Game(json) {
      this.game_id = parseInt(json.game_id);
      this.name = json.name;
      this.latitude = parseFloat(json.map_latitude);
      this.longitude = parseFloat(json.map_longitude);
      this.zoom = parseInt(json.map_zoom_level);
    }

    return Game;

  })();

  window.User = (function() {
    function User(json) {
      this.user_id = parseInt(json.user_id);
      this.display_name = json.display_name || json.user_name;
    }

    return User;

  })();

  window.Tag = (function() {
    function Tag(json) {
      var _ref, _ref1;
      this.icon_url = (_ref = json.media) != null ? (_ref1 = _ref.data) != null ? _ref1.url : void 0 : void 0;
      this.tag = json.tag;
      this.tag_id = parseInt(json.tag_id);
    }

    return Tag;

  })();

  window.Comment = (function() {
    function Comment(json) {
      this.description = json.description;
      this.comment_id = parseInt(json.note_comment_id);
      this.user = new User(json.user);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
    }

    return Comment;

  })();

  window.Note = (function() {
    function Note(json) {
      var comment, o;
      this.note_id = parseInt(json.note_id);
      this.user = new User(json.user);
      this.description = json.description;
      this.photo_url = parseInt(json.media.data.media_id) === 0 ? null : json.media.data.url;
      this.thumb_url = parseInt(json.media.data.media_id) === 0 ? null : json.media.data.thumb_url;
      this.latitude = parseFloat(json.latitude);
      this.longitude = parseFloat(json.longitude);
      this.tag_id = parseInt(json.tag_id);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.player_liked = parseInt(json.player_liked) !== 0;
      this.note_likes = parseInt(json.note_likes);
      this.comments = (function() {
        var _i, _len, _ref, _results;
        _ref = json.comments.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          o = _ref[_i];
          comment = new Comment(o);
          if (!comment.description.match(/\S/)) {
            continue;
          }
          _results.push(comment);
        }
        return _results;
      })();
      this.published = json.published;
    }

    return Note;

  })();

}).call(this);
