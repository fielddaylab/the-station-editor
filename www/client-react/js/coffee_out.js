(function() {
  var NoteView, SearchBox, TopLevel, renderMarkdown,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.Game = (function() {
    function Game(json) {
      this.game_id = parseInt(json.game_id);
      this.name = json.name;
      this.description = json.description;
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

  renderMarkdown = function(str) {
    return {
      __html: markdown.toHTML(str)
    };
  };

  NoteView = React.createClass({
    render: function() {
      var comment;
      return React.createElement("div", null, React.createElement("p", null, React.createElement("button", {
        "type": "button",
        "onClick": this.props.onBack
      }, "Back")), React.createElement("p", null, React.createElement("img", {
        "src": this.props.note.photo_url
      })), React.createElement("p", null, this.props.note.description), (function() {
        var _i, _len, _ref, _results;
        _ref = this.props.note.comments;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          comment = _ref[_i];
          _results.push(React.createElement("div", {
            "key": "comment-" + comment.comment_id
          }, React.createElement("h4", null, comment.user.display_name, ", ", comment.created.toLocaleString()), React.createElement("p", null, comment.description)));
        }
        return _results;
      }).call(this));
    }
  });

  SearchBox = React.createClass({
    handleChange: function() {
      var tag, tags, text;
      tags = (function() {
        var _i, _len, _ref, _results;
        _ref = this.props.tags;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tag = _ref[_i];
          if (this.refs["searchTag" + tag.tag_id].getDOMNode().checked) {
            _results.push(tag);
          }
        }
        return _results;
      }).call(this);
      text = this.refs.searchText.getDOMNode().value;
      return this.props.onSearch(tags, text);
    },
    render: function() {
      var tag;
      return React.createElement("form", null, (function() {
        var _i, _len, _ref, _results;
        _ref = this.props.tags;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tag = _ref[_i];
          _results.push(React.createElement("p", {
            "key": tag.tag_id
          }, React.createElement("label", null, React.createElement("input", {
            "type": "checkbox",
            "ref": "searchTag" + tag.tag_id,
            "checked": (__indexOf.call(this.props.checkedTags, tag) >= 0),
            "onChange": this.handleChange
          }), tag.tag)));
        }
        return _results;
      }).call(this), React.createElement("p", null, React.createElement("input", {
        "type": "text",
        "ref": "searchText",
        "value": this.props.searchText,
        "onChange": this.handleChange
      })));
    }
  });

  TopLevel = React.createClass({
    getInitialState: function() {
      return {
        notes: [],
        viewing: null,
        searching: false,
        checkedTags: [],
        searchText: ''
      };
    },
    componentDidMount: function() {
      return this.handleSearch([], '', false);
    },
    render: function() {
      var u;
      return React.createElement("div", null, React.createElement("h1", null, this.props.game.name), React.createElement("h2", null, "A Siftr by ", ((function() {
        var _i, _len, _ref, _results;
        _ref = this.props.game.owners;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          u = _ref[_i];
          _results.push(u.display_name);
        }
        return _results;
      }).call(this)).join(', ')), React.createElement("div", {
        "dangerouslySetInnerHTML": renderMarkdown(this.props.game.description)
      }), React.createElement("div", {
        "style": {
          width: '500px',
          height: '500px'
        }
      }, React.createElement(GoogleMapReact, {
        "center": [this.props.game.latitude, this.props.game.longitude],
        "zoom": this.props.game.zoom
      }, this.state.notes.map((function(_this) {
        return function(note) {
          return React.createElement("div", {
            "key": "marker-" + note.note_id,
            "lat": note.latitude,
            "lng": note.longitude,
            "style": {
              width: '10px',
              height: '10px',
              backgroundColor: 'black',
              cursor: 'pointer'
            },
            "onClick": (function() {
              return _this.setState({
                viewing: note
              });
            })
          });
        };
      })(this)))), (this.state.viewing != null ? React.createElement(NoteView, {
        "note": this.state.viewing,
        "onBack": ((function(_this) {
          return function() {
            return _this.setState({
              viewing: null
            });
          };
        })(this))
      }) : React.createElement("div", null, React.createElement(SearchBox, {
        "tags": this.props.game.tags,
        "checkedTags": this.state.checkedTags,
        "searchText": this.state.searchText,
        "onSearch": this.handleSearch
      }), (this.state.searching ? React.createElement("p", null, "Searching...") : this.state.notes.map((function(_this) {
        return function(note) {
          return React.createElement("a", {
            "key": "thumb-" + note.note_id,
            "href": "#",
            "onClick": (function() {
              return _this.setState({
                viewing: note
              });
            })
          }, React.createElement("img", {
            "src": note.thumb_url
          }));
        };
      })(this))))));
    },
    handleSearch: function(tags, text, wait) {
      var thisSearch;
      if (wait == null) {
        wait = true;
      }
      this.setState({
        checkedTags: tags,
        searchText: text
      });
      thisSearch = Date.now();
      this.setState({
        lastSearch: thisSearch,
        searching: true
      });
      return setTimeout((function(_this) {
        return function() {
          var tag, word;
          if (thisSearch === _this.state.lastSearch) {
            return _this.props.aris.call('notes.searchNotes', {
              game_id: _this.props.game.game_id,
              order_by: 'recent',
              tag_ids: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = tags.length; _i < _len; _i++) {
                  tag = tags[_i];
                  _results.push(tag.tag_id);
                }
                return _results;
              })(),
              search_terms: (function() {
                var _i, _len, _ref, _results;
                _ref = text.split(/\s+/);
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  word = _ref[_i];
                  if (word !== '') {
                    _results.push(word);
                  }
                }
                return _results;
              })()
            }, function(_arg) {
              var n, notes, o, returnCode;
              notes = _arg.data, returnCode = _arg.returnCode;
              if (thisSearch === _this.state.lastSearch) {
                _this.setState({
                  searching: false
                });
                if (returnCode === 0) {
                  return _this.setState({
                    notes: (function() {
                      var _i, _len, _results;
                      _results = [];
                      for (_i = 0, _len = notes.length; _i < _len; _i++) {
                        o = notes[_i];
                        n = new Note(o);
                        if (n.photo_url == null) {
                          continue;
                        }
                        _results.push(n);
                      }
                      return _results;
                    })()
                  });
                }
              }
            });
          }
        };
      })(this), wait ? 250 : 0);
    }
  });

  $(document).ready(function() {
    var aris;
    aris = new Aris;
    return aris.call('games.getGame', {
      game_id: 3967
    }, function(_arg) {
      var game, gameJson, returnCode;
      gameJson = _arg.data, returnCode = _arg.returnCode;
      if (returnCode === 0 && (gameJson != null)) {
        game = new Game(gameJson);
        return aris.call('tags.getTagsForGame', {
          game_id: game.game_id
        }, (function(_this) {
          return function(_arg1) {
            var o, returnCode, tags;
            tags = _arg1.data, returnCode = _arg1.returnCode;
            if (returnCode === 0) {
              game.tags = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = tags.length; _i < _len; _i++) {
                  o = tags[_i];
                  _results.push(new Tag(o));
                }
                return _results;
              })();
              return aris.call('users.getUsersForGame', {
                game_id: game.game_id
              }, function(_arg2) {
                var owners, returnCode;
                owners = _arg2.data, returnCode = _arg2.returnCode;
                if (returnCode === 0) {
                  game.owners = (function() {
                    var _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = owners.length; _i < _len; _i++) {
                      o = owners[_i];
                      _results.push(new User(o));
                    }
                    return _results;
                  })();
                  return React.render(React.createElement(TopLevel, {
                    "game": game,
                    "aris": aris
                  }), document.getElementById('output'));
                }
              });
            }
          };
        })(this));
      }
    });
  });

}).call(this);
