(function() {
  var App, app,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  App = (function() {
    function App() {
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          _this.isLoading = false;
          _this.selectPage('#page-loading');
          _this.isLoading = true;
          $('#button-login').click(function() {
            $('#spinner-login').show();
            _this.login($('#text-username').val(), $('#text-password').val(), function() {
              $('#spinner-login').hide();
              if (_this.aris.auth != null) {
                return _this.startingPage();
              } else {
                return _this.showAlert('Incorrect username or password.');
              }
            });
            return false;
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
              _this.aris.call('users.createUser', {
                user_name: $('#text-new-username').val(),
                password: $('#text-new-password').val(),
                email: $('#text-new-email').val()
              }, function(res) {
                if (res.returnCode !== 0) {
                  return _this.showAlert("Couldn't create account: " + res.returnCodeDescription);
                } else {
                  _this.parseLogin(res);
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
              _this.aris.call('users.changePassword', {
                user_name: _this.aris.auth.username,
                old_password: $('#text-old-password').val(),
                new_password: $('#text-change-password').val()
              }, function(res) {
                if (res.returnCode !== 0) {
                  return _this.showAlert("Couldn't change password: " + res.returnCodeDescription);
                } else {
                  _this.parseLogin(res);
                  return _this.startingPage();
                }
              });
            }
            return false;
          });
          $(window).on('hashchange', function() {
            return _this.goToHash();
          });
          _this.updateNav();
          return _this.login(void 0, void 0, function() {
            _this.isLoading = false;
            return _this.goToHash();
          });
        };
      })(this));
    }

    App.prototype.showAlert = function(str) {
      $('#the-alert').text(str);
      return $('#the-alert').show();
    };

    App.prototype.startingPage = function() {
      if (this.aris.auth != null) {
        return this.selectPage('#page-list');
      } else {
        return this.selectPage('#page-login');
      }
    };

    App.prototype.updateNav = function() {
      if (this.aris.auth != null) {
        $('#span-username').text(this.aris.auth.username);
        $('#dropdown-logged-in').show();
        return $('#nav-left-logged-in').show();
      } else {
        $('#dropdown-logged-in').hide();
        return $('#nav-left-logged-in').hide();
      }
    };

    App.prototype.parseLogin = function(obj) {
      this.aris.parseLogin(obj);
      return this.updateNav();
    };

    App.prototype.login = function(username, password, cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.aris.login(username, password, (function(_this) {
        return function() {
          _this.updateNav();
          return _this.updateGameList(cb);
        };
      })(this));
    };

    App.prototype.logout = function() {
      this.aris.logout();
      return this.updateNav();
    };

    App.prototype.goToHash = function() {
      var g, game_id, games, h, res;
      h = document.location.hash;
      switch (h) {
        case '#password':
          if (this.aris.auth != null) {
            return this.selectPage('#page-change-password');
          } else {
            return this.startingPage();
          }
          break;
        case '#logout':
          this.logout();
          return document.location.hash = '';
        case '#join':
          if (this.aris.auth != null) {
            return this.startingPage();
          } else {
            return this.selectPage('#page-new-acct');
          }
          break;
        default:
          if (this.aris.auth != null) {
            if ((res = h.match(/^#edit(\d+)$/)) != null) {
              game_id = parseInt(res[1]);
              games = (function() {
                var _i, _len, _ref, _results;
                _ref = this.games;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  g = _ref[_i];
                  if (g.game_id === game_id) {
                    _results.push(g);
                  }
                }
                return _results;
              }).call(this);
              if (games.length !== 0) {
                return this.startEdit(games[0]);
              } else {
                return this.startingPage();
              }
            } else if ((res = h.match(/^#tags(\d+)$/)) != null) {
              game_id = parseInt(res[1]);
              games = (function() {
                var _i, _len, _ref, _results;
                _ref = this.games;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  g = _ref[_i];
                  if (g.game_id === game_id) {
                    _results.push(g);
                  }
                }
                return _results;
              }).call(this);
              if (games.length !== 0) {
                return this.startEditTags(games[0]);
              } else {
                return this.startingPage();
              }
            } else {
              return this.startingPage();
            }
          } else {
            return this.startingPage();
          }
      }
    };

    App.prototype.selectPage = function(page) {
      if (this.isLoading) {
        return;
      }
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
                return appendTo(mediaLeft, '.media-object', {
                  style: "width: 64px;\nheight: 64px;\nbackground-image: url(" + game.icon_media.url + ");\nbackground-size: contain;\nbackground-repeat: no-repeat;\nbackground-position: center;"
                });
              });
              return appendTo(media, '.media-body', {}, function(mediaBody) {
                var _ref1;
                appendTo(mediaBody, 'a', {
                  href: "" + SIFTR_URL + "?" + ((_ref1 = game.siftr_url) != null ? _ref1 : game.game_id),
                  target: '_blank'
                }, function(siftrLink) {
                  return appendTo(siftrLink, 'h4.media-heading', {
                    text: game.name
                  });
                });
                appendTo(mediaBody, 'p', {
                  text: game.description
                });
                return appendTo(mediaBody, 'form', {}, function(form) {
                  return appendTo(form, '.form-group', {}, function(formGroup) {
                    appendTo(formGroup, 'a.btn.btn-primary', {
                      href: '#edit' + game.game_id,
                      text: 'Edit Siftr'
                    });
                    appendTo(formGroup, 'a.btn.btn-default', {
                      href: '#tags' + game.game_id,
                      text: 'Edit tags'
                    });
                    return appendTo(formGroup, 'a.btn.btn-danger', {
                      href: '#',
                      html: '<i class="fa fa-remove"></i> Delete Siftr'
                    }, function(button) {
                      return button.click(function() {
                        _this.deleteGame = game;
                        $('#modal-delete-siftr .modal-body').text("Are you sure you want to delete \"" + game.name + "\"?");
                        return $('#modal-delete-siftr').modal();
                      });
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
      if (this.aris.auth != null) {
        return this.getGames((function(_this) {
          return function() {
            return _this.getGameIcons(function() {
              return _this.getGameTags(function() {
                return _this.getGameTagCounts(function() {
                  _this.redrawGameList();
                  return cb();
                });
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
        map_zoom_level: parseInt(json.map_zoom_level),
        siftr_url: json.siftr_url || null
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
      return this.aris.call('games.getGamesForUser', {}, (function(_this) {
        return function(_arg) {
          var games, json, _i, _len;
          games = _arg.data;
          _this.games = [];
          for (_i = 0, _len = games.length; _i < _len; _i++) {
            json = games[_i];
            if ((json.is_siftr != null) && !parseInt(json.is_siftr)) {
              continue;
            }
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
          if (parseInt(game.icon_media_id) === 0) {
            game.icon_media = {
              url: 'img/uw_shield.png'
            };
            this.getGameIcons(cb);
          } else {
            this.aris.call('media.getMedia', {
              media_id: game.icon_media_id
            }, (function(_this) {
              return function(_arg) {
                game.icon_media = _arg.data;
                return _this.getGameIcons(cb);
              };
            })(this));
          }
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
          this.aris.call('tags.getTagsForGame', {
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

    App.prototype.getGameTagCounts = function(cb) {
      var game, tag, _i, _j, _len, _len1, _ref, _ref1;
      if (cb == null) {
        cb = (function() {});
      }
      _ref = this.games;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        game = _ref[_i];
        _ref1 = game.tags;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          tag = _ref1[_j];
          if (tag.count == null) {
            this.aris.call('tags.countObjectsWithTag', {
              object_type: 'NOTE',
              tag_id: tag.tag_id
            }, (function(_this) {
              return function(_arg) {
                var count;
                count = _arg.data.count;
                tag.count = parseInt(count);
                return _this.getGameTagCounts(cb);
              };
            })(this));
            return;
          }
        }
      }
      return cb();
    };

    App.prototype.resetIcon = function() {
      $('#div-icon-input').fileinput('clear');
      $('#div-icon-thumb').html('');
      return appendTo($('#div-icon-thumb'), 'img', {
        src: this.currentGame.icon_media.url
      });
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
      }
      return parent.append(this.map.getDiv());
    };

    App.prototype.startEdit = function(game) {
      if (game == null) {
        game = this.currentGame;
      }
      this.currentGame = game;
      $('#text-siftr-name').val(game.name);
      $('#text-siftr-desc').val(game.description);
      $('#text-siftr-url').val(game.siftr_url);
      this.resetIcon();
      this.createMap($('#div-google-map'), {
        lat: game.map_latitude,
        lng: game.map_longitude,
        zoom: game.map_zoom_level
      });
      $('#code-siftr-url-template').text("" + window.SIFTR_URL + "<your-siftr-url>");
      return this.selectPage('#page-edit');
    };

    App.prototype.uploadMediaFromInput = function(input, game, cb) {
      var reader;
      reader = new FileReader;
      reader.onload = (function(_this) {
        return function(e) {
          var base64, dataURL, ext, extmap, k, v;
          dataURL = e.target.result;
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
          if ((ext != null) && (base64 != null)) {
            return _this.aris.call('media.createMedia', {
              game_id: game.game_id,
              file_name: "upload." + ext,
              data: base64
            }, cb);
          } else {
            return cb(false);
          }
        };
      })(this);
      return reader.readAsDataURL($(input)[0].files[0]);
    };

    App.prototype.getIconID = function(cb) {
      if (cb == null) {
        cb = (function() {});
      }
      if ($('#file-siftr-icon')[0].files.length === 0) {
        return cb(this.currentGame.icon_media_id);
      } else {
        return this.uploadMediaFromInput('#file-siftr-icon', this.currentGame, (function(_this) {
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
          return _this.aris.call('games.updateGame', {
            game_id: _this.currentGame.game_id,
            name: $('#text-siftr-name').val(),
            description: $('#text-siftr-desc').val(),
            siftr_url: $('#text-siftr-url').val(),
            map_latitude: pn.lat(),
            map_longitude: pn.lng(),
            map_zoom_level: _this.map.getZoom(),
            icon_media_id: media_id
          }, function(_arg) {
            var json, newGame, returnCode, returnCodeDescription;
            json = _arg.data, returnCode = _arg.returnCode, returnCodeDescription = _arg.returnCodeDescription;
            if (returnCode !== 0) {
              _this.showAlert(returnCodeDescription);
              return $('#spinner-edit-save').hide();
            } else {
              newGame = _this.addGameFromJson(json);
              return _this.getGameIcons(function() {
                return _this.getGameTags(function() {
                  return _this.getGameTagCounts(function() {
                    _this.redrawGameList();
                    $('#spinner-edit-save').hide();
                    _this.startEdit(newGame);
                    return cb(newGame);
                  });
                });
              });
            }
          });
        };
      })(this));
    };

    App.prototype.makeNewSiftr = function() {
      $('#spinner-new-siftr').show();
      return this.aris.call('games.createGame', {
        name: 'Your New Siftr',
        description: 'Click "Edit Siftr" to get started.',
        map_latitude: 43.071644,
        map_longitude: -89.400658,
        map_zoom_level: 14,
        is_siftr: 1
      }, (function(_this) {
        return function(_arg) {
          var game;
          game = _arg.data;
          _this.addGameFromJson(game);
          return _this.aris.call('tags.createTag', {
            game_id: game.game_id,
            tag: 'Your First Tag'
          }, function(_arg1) {
            var tag;
            tag = _arg1.data;
            return _this.getGameIcons(function() {
              return _this.getGameTags(function() {
                return _this.getGameTagCounts(function() {
                  _this.redrawGameList();
                  return $('#spinner-new-siftr').hide();
                });
              });
            });
          });
        };
      })(this));
    };

    App.prototype.ableEditTags = function() {
      if ($('#div-edit-tags').children().length === 1) {
        $('.delete-tag').addClass('disabled');
      } else {
        $('.delete-tag').removeClass('disabled');
      }
      if ($('#div-edit-tags').children().length >= 8) {
        return $('#button-add-tag').addClass('disabled');
      } else {
        return $('#button-add-tag').removeClass('disabled');
      }
    };

    App.prototype.addTagEditor = function(tag) {
      appendTo($('#div-edit-tags'), '.media', {}, (function(_this) {
        return function(media) {
          appendTo(media, '.media-left', {}, function(mediaLeft) {
            return appendTo(mediaLeft, '.fileinput.fileinput-new', {
              'data-provides': 'fileinput'
            }, function(fileInput) {
              var thumb;
              thumb = appendTo(fileInput, '.fileinput-preview.thumbnail', {
                'data-trigger': 'fileinput',
                style: 'width: 64px; height: 64px;'
              }, function(thumb) {
                var _ref, _ref1;
                return appendTo(thumb, 'img', {
                  src: tag != null ? (_ref = tag.media) != null ? (_ref1 = _ref.data) != null ? _ref1.url : void 0 : void 0 : void 0
                });
              });
              return appendTo(fileInput, 'input.new-tag-icon', {
                type: 'file',
                name: '...',
                style: 'display: none;'
              }, function(iconInput) {
                return iconInput.change(function() {
                  thumb.addClass('icon-uploading');
                  return _this.uploadMediaFromInput(iconInput, _this.currentGame, function(_arg) {
                    var media;
                    media = _arg.data;
                    return _this.aris.call('tags.updateTag', {
                      tag_id: tag.tag_id,
                      media_id: media.media_id
                    }, function(_arg1) {
                      var newTag;
                      newTag = _arg1.data;
                      thumb.removeClass('icon-uploading');
                      tag.media = newTag.media;
                      return tag.media_id = newTag.media_id;
                    });
                  });
                });
              });
            });
          });
          return appendTo(media, '.media-body', {}, function(mediaBody) {
            return appendTo(mediaBody, 'form', {}, function(form) {
              appendTo(form, '.form-group.has-success', {}, function(formGroup) {
                return appendTo(formGroup, '.input-group', {}, function(inputGroup) {
                  var edited, input, lastEdited, lastUploaded, onEdit, saved, uploading;
                  lastEdited = Date.now();
                  lastUploaded = Date.now();
                  input = appendTo(inputGroup, 'input.form-control', {
                    type: 'text',
                    placeholder: 'Tag',
                    val: tag.tag
                  });
                  appendTo(inputGroup, 'span.input-group-addon', {
                    text: tag.count === 1 ? "1 note" : "" + tag.count + " notes"
                  });
                  saved = edited = uploading = null;
                  appendTo(inputGroup, 'span.input-group-addon', {}, function(addon) {
                    saved = appendTo(addon, 'i.fa.fa-check');
                    edited = appendTo(addon, 'i.fa.fa-edit', {
                      style: 'display: none;'
                    });
                    return uploading = appendTo(addon, 'i.fa.fa-spinner.fa-pulse', {
                      style: 'display: none;'
                    });
                  });
                  onEdit = function() {
                    var thisEdited;
                    lastEdited = thisEdited = Date.now();
                    saved.hide();
                    edited.show();
                    uploading.hide();
                    formGroup.removeClass('has-success');
                    return setTimeout(function() {
                      var newValue, thisUploaded;
                      if (lastEdited === thisEdited) {
                        lastUploaded = thisUploaded = Date.now();
                        saved.hide();
                        edited.hide();
                        uploading.show();
                        newValue = input.val();
                        return _this.aris.call('tags.updateTag', {
                          tag_id: tag.tag_id,
                          tag: newValue
                        }, function() {
                          tag.tag = newValue;
                          if (lastUploaded === thisUploaded) {
                            if (lastEdited < thisUploaded) {
                              saved.show();
                              edited.hide();
                              uploading.hide();
                              return formGroup.addClass('has-success');
                            } else {

                            }
                          } else {

                          }
                        });
                      }
                    }, 500);
                  };
                  return input.keydown(onEdit);
                });
              });
              return appendTo(form, '.form-group', {}, function(formGroup) {
                return appendTo(formGroup, 'button.btn.btn-danger.delete-tag', {
                  type: 'button',
                  html: '<i class="fa fa-remove"></i> Delete tag'
                }, function(btn) {
                  return btn.click(function() {
                    var message;
                    _this.tagToDelete = tag;
                    _this.tagEditorToDelete = media;
                    message = "Are you sure you want to delete the tag \"" + tag.tag + "\"?";
                    switch (tag.count) {
                      case 0:
                        null;
                        break;
                      case 1:
                        message += " 1 note with this tag will be deleted.";
                        break;
                      default:
                        message += " " + tag.count + " notes with this tag will be deleted.";
                    }
                    $('#modal-delete-tag .modal-body').text(message);
                    return $('#modal-delete-tag').modal();
                  });
                });
              });
            });
          });
        };
      })(this));
      return this.ableEditTags();
    };

    App.prototype.startEditTags = function(game) {
      var tag, _i, _len, _ref;
      this.currentGame = game;
      $('#div-edit-tags').html('');
      _ref = game.tags;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tag = _ref[_i];
        this.addTagEditor(tag);
      }
      return this.selectPage('#page-edit-tags');
    };

    App.prototype.editAddTag = function() {
      $('#spinner-add-tag').show();
      return this.aris.call('tags.createTag', {
        game_id: this.currentGame.game_id
      }, (function(_this) {
        return function(res) {
          var tag;
          if (res.returnCode === 0) {
            tag = res.data;
            tag.count = 0;
            _this.currentGame.tags.push(tag);
            _this.addTagEditor(tag);
          } else {
            _this.showAlert(res.returnCodeDescription);
          }
          return $('#spinner-add-tag').hide();
        };
      })(this));
    };

    App.prototype.deleteTag = function() {
      $('#spinner-delete-tag').show();
      return this.aris.call('tags.deleteTag', {
        tag_id: this.tagToDelete.tag_id
      }, (function(_this) {
        return function(res) {
          var t;
          if (res.returnCode === 0) {
            _this.tagEditorToDelete.remove();
            _this.ableEditTags();
            _this.currentGame.tags = (function() {
              var _i, _len, _ref, _results;
              _ref = this.currentGame.tags;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                t = _ref[_i];
                if (t !== this.tagToDelete) {
                  _results.push(t);
                }
              }
              return _results;
            }).call(_this);
          } else {
            _this.showAlert(res.returnCodeDescription);
          }
          $('#spinner-delete-tag').hide();
          return $('#modal-delete-tag').modal('hide');
        };
      })(this));
    };

    App.prototype.deleteSiftr = function() {
      $('#spinner-delete-siftr').show();
      return this.aris.call('games.deleteGame', {
        game_id: this.deleteGame.game_id
      }, (function(_this) {
        return function(res) {
          var g;
          if (res.returnCode === 0) {
            _this.games = (function() {
              var _i, _len, _ref, _results;
              _ref = this.games;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                g = _ref[_i];
                if (g !== this.deleteGame) {
                  _results.push(g);
                }
              }
              return _results;
            }).call(_this);
            _this.redrawGameList();
          } else {
            _this.showAlert(res.returnCodeDescription);
          }
          $('#modal-delete-siftr').modal('hide');
          return $('#spinner-delete-siftr').hide();
        };
      })(this));
    };

    return App;

  })();

  app = new App;

  window.app = app;

}).call(this);