(function() {
  var App, Results;

  Results = (function() {
    function Results(cells, games) {
      this.cells = cells;
      this.games = games;
      this.index = 0;
      this.updateCells();
    }

    Results.prototype.moveLeft = function() {
      if (this.index - 4 >= 0) {
        this.index -= 4;
        return this.updateCells();
      }
    };

    Results.prototype.moveRight = function() {
      if (this.index + 4 < this.games.length) {
        this.index += 4;
        return this.updateCells();
      }
    };

    Results.prototype.updateCells = function() {
      var cell, i, _i, _len, _ref, _results;
      _ref = this.cells;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        cell = _ref[i];
        _results.push(this.updateCell(cell, this.games[i + this.index]));
      }
      return _results;
    };

    Results.prototype.updateCell = function(cell, game) {
      var link, _ref;
      if (game != null) {
        link = "" + SIFTR_URL + ((_ref = game.siftr_url) != null ? _ref : game.game_id);
        if (game.go_to_note != null) {
          link += '#' + game.go_to_note;
        }
        $(cell).find('a').attr('href', link);
        $(cell).find('img').attr('src', game.icon_url);
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

    return Results;

  })();

  App = (function() {
    function App() {
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
                  var cells;
                  cells = $('#row-search').children('.siftr-cell');
                  _this.search = new Results(cells, games);
                  $('#search-results').show();
                  return $('.siftr-description').trigger('update');
                });
              });
            }
          });
          return _this.aris.login(void 0, void 0, function() {
            _this.updateNav();
            _this.aris.call('games.searchSiftrs', {
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
                var cells;
                cells = $('#row-recent').children('.siftr-cell');
                return _this.recent = new Results(cells, games);
              });
            });
            return _this.aris.call('games.searchSiftrs', {
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
                var cells;
                cells = $('#row-popular').children('.siftr-cell');
                return _this.popular = new Results(cells, games);
              });
            });
          });
        };
      })(this));
    }

    App.prototype.getIconURL = function(game) {
      return (function(_this) {
        return function(cb) {
          if (game.icon_url != null) {
            cb();
            return;
          }
          return _this.aris.call('notes.searchNotes', {
            game_id: game.game_id,
            note_count: 1,
            order_by: 'recent'
          }, function(_arg) {
            var notes;
            notes = _arg.data;
            if (notes.length === 0) {
              if (parseInt(game.icon_media_id) === 0) {
                game.icon_url = 'editor/img/uw_shield.png';
                return cb();
              } else {
                return _this.aris.call('media.getMedia', {
                  media_id: game.icon_media_id
                }, function(_arg1) {
                  var media;
                  media = _arg1.data;
                  game.icon_url = media.url;
                  return cb();
                });
              }
            } else {
              game.icon_url = notes[0].media.data.url;
              game.go_to_note = parseInt(notes[0].note_id);
              return cb();
            }
          });
        };
      })(this);
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
