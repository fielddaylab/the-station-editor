(function() {
  var App, Game, Tag, User, app;

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
                  return null;
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
