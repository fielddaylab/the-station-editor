(function() {
  'use strict';
  var $, ARIS_URL, Aris, Comment, Game, Note, SIFTR_URL, Tag, User, k, v, _ref;

  $ = require('jquery');

  ARIS_URL = 'http://arisgames.org/server/';

  SIFTR_URL = window.location.origin + '/';

  Game = (function() {
    function Game(json) {
      if (json != null) {
        this.game_id = parseInt(json.game_id);
        this.name = json.name;
        this.description = json.description;
        this.latitude = parseFloat(json.map_latitude);
        this.longitude = parseFloat(json.map_longitude);
        this.zoom = parseInt(json.map_zoom_level);
        this.siftr_url = json.siftr_url || null;
        this.is_siftr = parseInt(json.is_siftr) ? true : false;
        this.published = parseInt(json.published) ? true : false;
        this.moderated = parseInt(json.moderated) ? true : false;
      } else {
        this.game_id = null;
        this.name = null;
        this.description = null;
        this.latitude = null;
        this.longitude = null;
        this.zoom = null;
        this.siftr_url = null;
        this.is_siftr = null;
        this.published = null;
        this.moderated = null;
      }
    }

    Game.prototype.createJSON = function() {
      return {
        game_id: this.game_id || void 0,
        name: this.name,
        description: this.description,
        map_latitude: this.latitude,
        map_longitude: this.longitude,
        map_zoom_level: this.zoom,
        siftr_url: this.siftr_url,
        is_siftr: this.is_siftr,
        published: this.published,
        moderated: this.moderated
      };
    };

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
      var _ref, _ref1;
      this.icon_url = (_ref = json.media) != null ? (_ref1 = _ref.data) != null ? _ref1.url : void 0 : void 0;
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

  Aris = (function() {
    function Aris() {
      var authJSON;
      authJSON = window.localStorage['aris-auth'];
      this.auth = authJSON != null ? JSON.parse(authJSON) : null;
    }

    Aris.prototype.parseLogin = function(_arg) {
      var returnCode, user;
      user = _arg.data, returnCode = _arg.returnCode;
      if (returnCode === 0 && user.user_id !== null) {
        this.auth = {
          user_id: parseInt(user.user_id),
          permission: 'read_write',
          key: user.read_write_key,
          username: user.user_name
        };
        return window.localStorage['aris-auth'] = JSON.stringify(this.auth);
      } else {
        return this.logout();
      }
    };

    Aris.prototype.login = function(username, password, cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.call('users.logIn', {
        user_name: username,
        password: password,
        permission: 'read_write'
      }, (function(_this) {
        return function(res) {
          _this.parseLogin(res);
          return cb();
        };
      })(this));
    };

    Aris.prototype.logout = function() {
      this.auth = null;
      return window.localStorage.removeItem('aris-auth');
    };

    Aris.prototype.call = function(func, json, cb) {
      if (this.auth != null) {
        json.auth = this.auth;
      }
      return $.ajax({
        contentType: 'application/json',
        data: JSON.stringify(json),
        dataType: 'json',
        success: cb,
        error: function() {
          return cb(false);
        },
        processData: false,
        type: 'POST',
        url: "" + ARIS_URL + "/json.php/v2." + func
      });
    };

    Aris.prototype.callWrapped = function(func, json, cb, wrap) {
      return this.call(func, json, (function(_this) {
        return function(result) {
          if (result.returnCode === 0 && (result.data != null)) {
            result.data = wrap(result.data);
          }
          return cb(result);
        };
      })(this));
    };

    Aris.prototype.getGame = function(json, cb) {
      return this.callWrapped('games.getGame', json, cb, function(data) {
        return new Game(data);
      });
    };

    Aris.prototype.getTagsForGame = function(json, cb) {
      return this.callWrapped('tags.getTagsForGame', json, cb, function(data) {
        var o, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          o = data[_i];
          _results.push(new Tag(o));
        }
        return _results;
      });
    };

    Aris.prototype.getUsersForGame = function(json, cb) {
      return this.callWrapped('users.getUsersForGame', json, cb, function(data) {
        var o, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          o = data[_i];
          _results.push(new User(o));
        }
        return _results;
      });
    };

    Aris.prototype.getGamesForUser = function(json, cb) {
      return this.callWrapped('games.getGamesForUser', json, cb, function(data) {
        var o, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          o = data[_i];
          _results.push(new Game(o));
        }
        return _results;
      });
    };

    Aris.prototype.searchNotes = function(json, cb) {
      return this.callWrapped('notes.searchNotes', json, cb, function(data) {
        var o, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          o = data[_i];
          _results.push(new Note(o));
        }
        return _results;
      });
    };

    Aris.prototype.updateGame = function(game, cb) {
      return this.callWrapped('games.updateGame', game.createJSON(), cb, function(data) {
        return new Game(data);
      });
    };

    return Aris;

  })();

  _ref = {
    Game: Game,
    User: User,
    Tag: Tag,
    Comment: Comment,
    Note: Note,
    Aris: Aris,
    ARIS_URL: ARIS_URL,
    SIFTR_URL: SIFTR_URL
  };
  for (k in _ref) {
    v = _ref[k];
    exports[k] = v;
  }

}).call(this);
