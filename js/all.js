(function() {
  var App,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  App = (function() {
    function App() {
      this.updateCell = __bind(this.updateCell, this);
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          $('#menu-logout').click(function() {
            _this.aris.logout();
            return _this.updateNav();
          });
          $('#search-button').click(function() {
            return _this.aris.call('games.searchSiftrs', {
              count: 4,
              search: $('#search-text').val()
            }, function(_arg) {
              var game, games;
              games = _arg.data;
              return async.parallel((function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = games.length; _i < _len; _i++) {
                  game = games[_i];
                  _results.push(this.getIconURL(game));
                }
                return _results;
              }).call(_this), function() {
                var cells, i, _i, _len;
                cells = $('#row-search').children();
                for (i = _i = 0, _len = games.length; _i < _len; i = ++_i) {
                  game = games[i];
                  _this.updateCell(cells[i], game);
                }
                return $('#search-results').show();
              });
            });
          });
          return _this.aris.login(void 0, void 0, function() {
            _this.updateNav();
            _this.aris.call('games.searchSiftrs', {
              count: 4,
              order_by: 'recent'
            }, function(_arg) {
              var game, games;
              games = _arg.data;
              return async.parallel((function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = games.length; _i < _len; _i++) {
                  game = games[_i];
                  _results.push(this.getIconURL(game));
                }
                return _results;
              }).call(_this), function() {
                var cells, i, _i, _len, _results;
                cells = $('#row-recent').children();
                _results = [];
                for (i = _i = 0, _len = games.length; _i < _len; i = ++_i) {
                  game = games[i];
                  _results.push(_this.updateCell(cells[i], game));
                }
                return _results;
              });
            });
            return _this.aris.call('games.searchSiftrs', {
              count: 4,
              order_by: 'popular'
            }, function(_arg) {
              var game, games;
              games = _arg.data;
              return async.parallel((function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = games.length; _i < _len; _i++) {
                  game = games[_i];
                  _results.push(this.getIconURL(game));
                }
                return _results;
              }).call(_this), function() {
                var cells, i, _i, _len, _results;
                cells = $('#row-popular').children();
                _results = [];
                for (i = _i = 0, _len = games.length; _i < _len; i = ++_i) {
                  game = games[i];
                  _results.push(_this.updateCell(cells[i], game));
                }
                return _results;
              });
            });
          });
        };
      })(this));
    }

    App.prototype.getIconURL = function(game) {
      return (function(_this) {
        return function(cb) {
          return _this.aris.call('media.getMedia', {
            media_id: game.icon_media_id
          }, function(_arg) {
            var media;
            media = _arg.data;
            game.icon_url = media.url;
            return cb();
          });
        };
      })(this);
    };

    App.prototype.updateCell = function(cell, game) {
      var _ref;
      $(cell).find('a').attr('href', "" + SIFTR_URL + "?" + ((_ref = game.siftr_url) != null ? _ref : game.game_id));
      return $(cell).find('img').attr('src', parseInt(game.icon_media_id) === 0 ? 'editor/img/uw_shield.png' : game.icon_url);
    };

    App.prototype.updateNav = function() {
      if (this.aris.auth != null) {
        $('#span-username').text(this.aris.auth.username);
        return $('#dropdown-logged-in').show();
      } else {
        return $('#dropdown-logged-in').hide();
      }
    };

    return App;

  })();

  window.app = new App;

}).call(this);
