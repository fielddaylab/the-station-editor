(function() {
  var App,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  App = (function() {
    function App() {
      this.updateCell = __bind(this.updateCell, this);
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
          $('.siftr-description').dotdotdot({
            watch: 'window',
            height: 50
          });
          $('#menu-logout').click(function() {
            _this.aris.logout();
            return _this.updateNav();
          });
          $('#search-button').click(function() {
            var searchText;
            searchText = $('#search-text').val();
            if (searchText === '') {
              return $('#search-results').hide();
            } else {
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
                  var cell, cells, i, _i, _len;
                  cells = $('#row-search').children('.siftr-cell');
                  for (i = _i = 0, _len = cells.length; _i < _len; i = ++_i) {
                    cell = cells[i];
                    _this.updateCell(cell, games[i]);
                  }
                  $('#search-results').show();
                  return $('.siftr-description').trigger('update');
                });
              });
            }
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
                var cell, cells, i, _i, _len, _results;
                cells = $('#row-recent').children('.siftr-cell');
                _results = [];
                for (i = _i = 0, _len = cells.length; _i < _len; i = ++_i) {
                  cell = cells[i];
                  _results.push(_this.updateCell(cell, games[i]));
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
                var cell, cells, i, _i, _len, _results;
                cells = $('#row-popular').children('.siftr-cell');
                _results = [];
                for (i = _i = 0, _len = cells.length; _i < _len; i = ++_i) {
                  cell = cells[i];
                  _results.push(_this.updateCell(cell, games[i]));
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
          return _this.aris.call('notes.searchNotes', {
            game_id: game.game_id,
            note_count: 1,
            order_by: 'recent'
          }, function(_arg) {
            var notes;
            notes = _arg.data;
            if (notes.length === 0) {
              return _this.aris.call('media.getMedia', {
                media_id: game.icon_media_id
              }, function(_arg1) {
                var media;
                media = _arg1.data;
                game.icon_url = media.url;
                return cb();
              });
            } else {
              game.icon_url = notes[0].media.data.url;
              game.go_to_note = parseInt(notes[0].note_id);
              return cb();
            }
          });
        };
      })(this);
    };

    App.prototype.updateCell = function(cell, game) {
      var link, _ref;
      if (game != null) {
        link = "" + SIFTR_URL + "?" + ((_ref = game.siftr_url) != null ? _ref : game.game_id);
        if (game.go_to_note != null) {
          link += '#' + game.go_to_note;
        }
        $(cell).find('a').attr('href', link);
        $(cell).find('img').attr('src', parseInt(game.icon_media_id) === 0 ? 'editor/img/uw_shield.png' : game.icon_url);
        $(cell).find('img').show();
        $(cell).find('.siftr-title').text(game.name);
        return $(cell).find('.siftr-description').text(game.description);
      } else {
        $(cell).find('a').attr('href', '#');
        $(cell).find('img').removeAttr('src');
        $(cell).find('img').hide();
        $(cell).find('.siftr-title').text('');
        return $(cell).find('.siftr-description').text('');
      }
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
