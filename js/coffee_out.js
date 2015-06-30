(function() {
  var App, Results;

  Results = (function() {
    function Results(parent, games1, moreButton) {
      this.parent = parent;
      this.games = games1;
      this.moreButton = moreButton;
      this.showMore();
    }

    Results.prototype.showMore = function() {
      var gamesToShow;
      gamesToShow = this.games.slice(0, 4);
      if (gamesToShow.length !== 0) {
        this.games = this.games.slice(4);
        if (this.games.length === 0) {
          this.moreButton.hide();
        } else {
          this.moreButton.show();
        }
        appendTo(this.parent, '.row', {}, (function(_this) {
          return function(row) {
            var appendGame;
            appendGame = function(game) {
              return appendTo(row, '.siftr-cell.col-xs-6.col-sm-3', {}, function(cell) {
                var desc, markdown, photo_url, ref, ref1, url;
                if (game != null) {
                  url = "" + SIFTR_URL + ((ref = game.siftr_url) != null ? ref : game.game_id);
                  photo_url = url + '#' + ((ref1 = game.go_to_note) != null ? ref1 : '');
                  appendTo(cell, 'a', {
                    href: photo_url
                  }, function(link) {
                    return appendTo(link, 'img.img-responsive.img-thumbnail.img-siftr-icon', {
                      src: game.icon_url
                    });
                  });
                  appendTo(cell, 'a', {
                    href: url
                  }, function(link) {
                    return appendTo(link, '.siftr-title', {
                      text: game.name
                    });
                  });
                  markdown = new Showdown.converter();
                  desc = appendTo(cell, '.siftr-description', {
                    html: markdown.makeHtml(game.description)
                  });
                  return desc.dotdotdot({
                    watch: 'window',
                    height: 50
                  });
                }
              });
            };
            appendGame(gamesToShow[0]);
            appendGame(gamesToShow[1]);
            appendTo(row, '.clearfix.visible-xs-block');
            appendGame(gamesToShow[2]);
            return appendGame(gamesToShow[3]);
          };
        })(this));
        return $('.siftr-description').trigger('update');
      }
    };

    return Results;

  })();

  App = (function() {
    function App() {
      $(function() {
        return FastClick.attach(document.body);
      });
      $(document).ready((function(_this) {
        return function() {
          _this.aris = new Aris;
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
              }, function(arg) {
                var g, game, games;
                games = arg.data;
                games = (function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = games.length; i < len; i++) {
                    g = games[i];
                    if (parseInt(g.published) !== 0) {
                      results.push(g);
                    }
                  }
                  return results;
                })();
                return async.parallel((function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = games.length; i < len; i++) {
                    game = games[i];
                    results.push(this.getIconURL(game));
                  }
                  return results;
                }).call(_this), function() {
                  $('#rows-search').text('');
                  $('#search-results').show();
                  return _this.search = new Results($('#rows-search'), games, $('#show-more-search'));
                });
              });
            }
          });
          return _this.aris.login(void 0, void 0, function() {
            _this.updateNav();
            _this.aris.call('games.searchSiftrs', {
              order_by: 'recent'
            }, function(arg) {
              var g, game, games;
              games = arg.data;
              games = (function() {
                var i, len, results;
                results = [];
                for (i = 0, len = games.length; i < len; i++) {
                  g = games[i];
                  if (parseInt(g.published) !== 0) {
                    results.push(g);
                  }
                }
                return results;
              })();
              return async.parallel((function() {
                var i, len, results;
                results = [];
                for (i = 0, len = games.length; i < len; i++) {
                  game = games[i];
                  results.push(this.getIconURL(game));
                }
                return results;
              }).call(_this), function() {
                return _this.recent = new Results($('#rows-recent'), games, $('#show-more-recent'));
              });
            });
            return _this.aris.call('games.searchSiftrs', {
              order_by: 'popular'
            }, function(arg) {
              var g, game, games;
              games = arg.data;
              games = (function() {
                var i, len, results;
                results = [];
                for (i = 0, len = games.length; i < len; i++) {
                  g = games[i];
                  if (parseInt(g.published) !== 0) {
                    results.push(g);
                  }
                }
                return results;
              })();
              return async.parallel((function() {
                var i, len, results;
                results = [];
                for (i = 0, len = games.length; i < len; i++) {
                  game = games[i];
                  results.push(this.getIconURL(game));
                }
                return results;
              }).call(_this), function() {
                return _this.popular = new Results($('#rows-popular'), games, $('#show-more-popular'));
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
          }, function(arg) {
            var notes;
            notes = arg.data;
            if (notes.length === 0) {
              if (parseInt(game.icon_media_id) === 0) {
                game.icon_url = 'editor/img/uw_shield.png';
                return cb();
              } else {
                return _this.aris.call('media.getMedia', {
                  media_id: game.icon_media_id
                }, function(arg1) {
                  var media;
                  media = arg1.data;
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
