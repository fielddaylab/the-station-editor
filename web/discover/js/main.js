import React from 'react';

import ReactDOM from 'react-dom';

import {make, child, raw, props} from '../../shared/react-writer';

import {Game, Colors, User, Tag, Comment, Note, Aris, ARIS_URL} from '../../shared/aris';

import update from 'immutability-helper';
import createClass from 'create-react-class';

import {markdown} from 'markdown';

const renderMarkdown = function(str) {
  return {
    __html: markdown.toHTML(str)
  };
};

const App = createClass({
  displayName: 'App',
  getInitialState: function() {
    return {
      recent: {
        page: 0,
        games: []
      },
      popular: {
        page: 0,
        games: []
      },
      search: {
        page: 0,
        games: []
      },
      text: '',
      icons: {},
      owners: {},
      owner_pictures: {},
      logged_in: window.localStorage['aris-auth'] != null
    };
  },
  componentDidMount: function() {
    this.recent(1);
    return this.popular(1);
  },
  fetchIcons: function(games) {
    return games.forEach((game) => {
      if (!((this.state.icons[game.game_id] != null) || parseInt(game.icon_media_id) === 0)) {
        return this.props.aris.call('media.getMedia', {
          media_id: game.icon_media_id
        }, ({
            returnCode,
            data: media
          }) => {
          if (returnCode === 0 && (media != null)) {
            return this.setState((prevState) => {
              return update(prevState, {
                icons: (() => {
                  var obj;
                  obj = {};
                  obj[game.game_id] = {
                    $set: media.thumb_url
                  };
                  return obj;
                })()
              });
            });
          }
        });
      }
    });
  },
  fetchOwners: function(games) {
    return games.forEach((game) => {
      if (this.state.owners[game.game_id] == null) {
        return this.props.aris.getUsersForGame({
          game_id: game.game_id
        }, ({
            returnCode,
            data: users
          }) => {
          if (returnCode === 0 && (users != null)) {
            this.setState((prevState) => {
              return update(prevState, {
                owners: (() => {
                  var obj;
                  obj = {};
                  obj[game.game_id] = {
                    $set: users
                  };
                  return obj;
                })()
              });
            });
            return this.fetchOwnerPictures(users);
          }
        });
      }
    });
  },
  fetchOwnerPictures: function(owners) {
    return owners.forEach((user) => {
      if (!((this.state.owner_pictures[user.user_id] != null) || parseInt(user.media_id) === 0)) {
        return this.props.aris.call('media.getMedia', {
          media_id: user.media_id
        }, ({
            returnCode,
            data: media
          }) => {
          if (returnCode === 0 && (media != null)) {
            return this.setState((prevState) => {
              return update(prevState, {
                owner_pictures: (() => {
                  var obj;
                  obj = {};
                  obj[user.user_id] = {
                    $set: media.thumb_url
                  };
                  return obj;
                })()
              });
            });
          }
        });
      }
    });
  },
  recent: function(page) {
    return this.props.aris.call('games.searchSiftrs', {
      count: 4,
      offset: (page - 1) * 4,
      order_by: 'recent'
    }, ({
        returnCode,
        data: games
      }) => {
      if (returnCode === 0 && (games != null)) {
        this.setState({
          recent: {page, games}
        });
        this.fetchIcons(games);
        return this.fetchOwners(games);
      }
    });
  },
  popular: function(page) {
    return this.props.aris.call('games.searchSiftrs', {
      count: 4,
      offset: (page - 1) * 4,
      order_by: 'popular'
    }, ({
        returnCode,
        data: games
      }) => {
      if (returnCode === 0 && (games != null)) {
        this.setState({
          popular: {page, games}
        });
        this.fetchIcons(games);
        return this.fetchOwners(games);
      }
    });
  },
  search: function(page, str = this.state.text) {
    return this.props.aris.call('games.searchSiftrs', {
      count: 4,
      offset: (page - 1) * 4,
      search: str
    }, ({
        returnCode,
        data: games
      }) => {
      if (returnCode === 0 && (games != null)) {
        this.setState({
          search: {page, games}
        });
        this.fetchIcons(games);
        return this.fetchOwners(games);
      }
    });
  },
  setText: function(str) {
    var thisSearch;
    this.setState({
      text: str
    });
    thisSearch = this.lastSearch = Date.now();
    return setTimeout(() => {
      if (thisSearch === this.lastSearch) {
        return this.search(1, str);
      }
    }, 300);
  },
  render: function() {
    var sections;
    sections = [
      {
        header: 'RECENT SIFTRS',
        identifier: 'recent'
      },
      {
        header: 'POPULAR SIFTRS',
        identifier: 'popular'
      }
    ];
    if (this.state.text !== '') {
      sections.unshift({
        header: `RESULTS FOR "${this.state.text}"`,
        identifier: 'search'
      });
    }
    return make('div', () => {
      child('div#banner.section.dark_bg', () => {
        child('div#top_bar', {
          style: {
            height: 50,
            padding: 30
          }
        }, () => {
          child('a', {
            href: '..'
          }, () => {
            return child('div.top_bar_logo', {
              style: {
                width: 57,
                height: 50
              }
            }, () => {
              return child('img', {
                src: "../assets/logos/siftr-nav-logo.png",
                style: {
                  width: '100%',
                  height: '100%'
                }
              });
            });
          });
          if (!this.state.logged_in) {
            child('a', {
              href: '../login/#signup'
            }, () => {
              return child('div.top_bar_link.signup_button', () => {
                return raw('SIGN UP');
              });
            });
            child('a', {
              href: '../login'
            }, () => {
              return child('div.top_bar_link', () => {
                return raw('LOGIN');
              });
            });
          }
          child('a', {
            href: ''
          }, () => {
            return child('div.top_bar_link', {
              style: {
                color: 'rgb(235,197,0)'
              }
            }, () => {
              return raw('DISCOVER');
            });
          });
          if (this.state.logged_in) {
            child('a', {
              href: '../editor/#account'
            }, () => {
              return child('div.top_bar_link', () => {
                return raw('MY ACCOUNT');
              });
            });
            return child('a', {
              href: '../editor'
            }, () => {
              return child('div.top_bar_link', () => {
                return raw('MY SIFTRS');
              });
            });
          }
        });
        child('div.spacer', {
          style: {
            height: 20
          }
        });
        child('div', {
          style: {
            maxWidth: '100%',
            width: '600px',
            margin: '0px auto',
            color: '#FF0000'
          }
        }, () => {
          return child('img', {
            src: "../assets/logos/siftr-main-logo.png",
            style: {
              width: '100%'
            }
          });
        });
        child('div.spacer', {
          style: {
            height: 30
          }
        });
        child('div#slogan', () => {
          return raw('EXPLORE YOUR WORLD, SHARE YOUR DISCOVERIES');
        });
        child('div.spacer', {
          style: {
            height: 60
          }
        });
        child('div', {
          style: {
            width: '600px',
            maxWidth: 'calc(100% - 10px)',
            margin: '0px auto'
          }
        }, () => {
          return child('input.search_bar', {
            type: 'text',
            placeholder: 'Search for a Siftr...',
            value: this.state.text,
            onChange: (e) => {
              return this.setText(e.target.value);
            }
          });
        });
        return child('div.spacer', {
          style: {
            height: 60
          }
        });
      });
      return sections.forEach(({header, identifier}) => {
        return child('div.section.white_bg.list_section', {
          key: `section_${identifier}`
        }, () => {
          var game, i, len, ref, url;
          child('div', {
            style: {
              textAlign: 'center',
              letterSpacing: 3,
              padding: 20
            }
          }, () => {
            child('h2', () => {
              return raw(header);
            });
            return child('h4', () => {
              child('b.results_arrow', () => {
                props({
                  onClick: () => {
                    if (this.state[identifier].page !== 1) {
                      return this[identifier](this.state[identifier].page - 1);
                    }
                  }
                });
                return raw(' < ');
              });
              raw(`page ${this.state[identifier].page}`);
              return child('b.results_arrow', () => {
                props({
                  onClick: () => {
                    return this[identifier](this.state[identifier].page + 1);
                  }
                });
                return raw(' > ');
              });
            });
          });
          ref = this.state[identifier].games;
          for (i = 0, len = ref.length; i < len; i++) {
            game = ref[i];
            url = game.siftr_url || game.game_id;
            child('a.list_entry', {
              key: game.game_id,
              href: `../${url}`,
              target: '_blank'
            }, () => {
              child('div.list_entry_faded', () => {
                child('span.list_link', {
                }, () => {
                  var ref1;
                  child('img.list_image', {
                    src: (ref1 = this.state.icons[game.game_id]) != null ? ref1 : '../assets/logos/siftr-nav-logo.png'
                  });
                  return child('h3.list_name', () => {
                    return raw(game.name);
                  });
                });
                child('div.list_description', {
                  dangerouslySetInnerHTML: renderMarkdown(game.description)
                });
                return child('div.list_fadeout');
              });
              return child('div.list_credit', () => {
                var owner;
                if (this.state.owners[game.game_id] != null) {
                  owner = this.state.owners[game.game_id][0];
                  return child('p', () => {
                    var chars, word;
                    if (this.state.owner_pictures[owner.user_id] != null) {
                      child('img.owner_picture', {
                        src: this.state.owner_pictures[owner.user_id]
                      });
                    } else {
                      chars = (function() {
                        var j, len1, ref1, results;
                        ref1 = owner.display_name.split(/\W+/);
                        results = [];
                        for (j = 0, len1 = ref1.length; j < len1; j++) {
                          word = ref1[j];
                          if (word !== '') {
                            results.push(word[0]);
                          }
                        }
                        return results;
                      })();
                      child('span.owner_picture', () => {
                        return raw(chars.join('').slice(0, 2).toUpperCase());
                      });
                    }
                    return raw(`By ${owner.display_name}`);
                  });
                }
              });
            });
          }
          return child('div', {
            style: {
              clear: 'both'
            }
          });
        });
      });
    });
  }
});

document.addEventListener("DOMContentLoaded", function() {
  return ReactDOM.render(React.createElement(App, {
    aris: new Aris
  }), document.getElementById('the-container'));
});
