'use strict';

import React from 'react';
import ReactDOM from 'react-dom';
import update from 'immutability-helper';
import {make, child, raw, props} from '../../shared/react-writer';
import createClass from "create-react-class";

import {markdown} from 'markdown';

import {
  ARIS_URL,
  SIFTR_URL,
  Game,
  Colors,
  Theme,
  User,
  arisHTTPS,
  Tag,
  Comment,
  Note,
  Field,
  FieldOption,
  FieldData,
  Aris,
} from '../../shared/aris';

import {AccountSettings} from './account-settings';
import {ProfileSettings} from './profile-settings';
import {MapOptions} from './map-options';
import {StationLocation} from './station-location';
import {SiftrList} from './siftr-list';
import {InnerNav} from './inner-nav';
import {MediaSelect} from './media-select';

function renderMarkdown(str) {
  return {
    __html: markdown.toHTML(str != null ? str : '')
  };
}

function singleObj(k, v) {
  var obj = {};
  obj[k] = v;
  return obj;
}

function onSuccess(fn) {
  return function({data, returnCode, returnCodeDescription}) {
    if (returnCode === 0) {
      return fn(data);
    } else {
      alert(`An error occurred: ${returnCodeDescription}`);
    }
  };
}

function hasNameDesc(game) {
  return (game.name != null) &&
    game.name.match(/\S/) &&
    (game.description != null) &&
    game.description.match(/\S/);
}

function standardFields() {
  return [];
}

function blankGame() {
  let g = new Game;
  g.colors_id = 1;
  g.theme_id = 1;
  g.map_show_labels = true;
  g.map_show_roads = true;
  g.map_type = 'STREET';
  g.latitude = 43.087806;
  g.longitude = -89.430121;
  g.zoom = 12;
  g.is_siftr = true;
  g.type = 'ANYWHERE';
  g.fields = standardFields();
  g.plaques = [];
  return g;
}

const App = createClass({
  displayName: 'App',
  getInitialState: function() {
    return {
      auth: null,
      games: [],
      tags: {},
      notes: {},
      forms: {},
      quests: {},
      plaques: {},
      triggers: {},
      instances: {},
      items: {},
      events: {},
      colors: {},
      themes: {},
      username: '',
      password: '',
      screen: 'main',
      edit_game: null,
      new_game: blankGame(),
      new_categories: [
        {
          category: '',
          color: undefined
        }
      ],
      new_icon: null,
      account_menu: false,
      modal_game: null
    };
  },
  componentDidMount: function() {
    this.login(undefined, undefined);
    this.applyHash();
    window.addEventListener('hashchange', () => {
      return this.applyHash();
    });
    this.getColorsAndThemes();
    document.addEventListener("keydown", (e) => {
      if (e.keyCode == 83 && (navigator.platform.match("Mac") ? e.metaKey : e.ctrlKey)) {
        e.preventDefault();
        this.saveQuest();
      }
    }, false);
  },
  applyHash: function() {
    var game, game_id, hash, matchingGames, md;
    this.setState({
      account_menu: false
    });
    hash = window.location.hash.slice(1);
    if ((md = hash.match(/^edit(.*)/)) != null) {
      game_id = parseInt(md[1]);
      matchingGames = (function() {
        var l, len, ref1, results;
        ref1 = this.state.games;
        results = [];
        for (l = 0, len = ref1.length; l < len; l++) {
          game = ref1[l];
          if (game.game_id === game_id) {
            results.push(game);
          }
        }
        return results;
      }).call(this);
      if (matchingGames.length === 1) {
        this.setState({
          screen: 'edit',
          mobile_map_is_open: false,
          edit_game: matchingGames[0]
        });
      } else {
        this.setState({
          screen: 'main'
        });
        // This is temporary if the user is currently being logged in,
        // because the list of games will load and re-call applyHash
      }
    } else if ((md = hash.match(/^form(.*)/)) != null) {
      game_id = parseInt(md[1]);
      matchingGames = (function() {
        var l, len, ref1, results;
        ref1 = this.state.games;
        results = [];
        for (l = 0, len = ref1.length; l < len; l++) {
          game = ref1[l];
          if (game.game_id === game_id) {
            results.push(game);
          }
        }
        return results;
      }).call(this);
      if (matchingGames.length === 1) {
        this.setState({
          screen: 'form',
          edit_game: matchingGames[0]
        });
      } else {
        this.setState({
          screen: 'main'
        });
        // This is temporary if the user is currently being logged in,
        // because the list of games will load and re-call applyHash
      }
    } else if ((md = hash.match(/^map(.*)/)) != null) {
      game_id = parseInt(md[1]);
      matchingGames = (function() {
        var l, len, ref1, results;
        ref1 = this.state.games;
        results = [];
        for (l = 0, len = ref1.length; l < len; l++) {
          game = ref1[l];
          if (game.game_id === game_id) {
            results.push(game);
          }
        }
        return results;
      }).call(this);
      if (matchingGames.length === 1) {
        this.setState({
          screen: 'map',
          edit_game: matchingGames[0]
        });
      } else {
        this.setState({
          screen: 'main'
        });
        // This is temporary if the user is currently being logged in,
        // because the list of games will load and re-call applyHash
      }
    } else if (hash === 'new1') {
      if (this.state.screen === 'main' || this.state.screen === 'profile' || this.state.screen === 'account') {
        this.setState({
          screen: 'new1',
          new_game: blankGame(),
        });
      } else {
        this.setState({
          screen: 'new1',
        });
      }
    } else if (hash === 'new2') {
      this.setState({
        screen: 'new2',
      });
    } else if (['quest1', 'quest2', 'quest3', 'quest4', 'quest5'].indexOf(hash) !== -1) {
      if (this.state.edit_game) {
        this.setState({
          screen: hash,
        });
      } else {
        window.location.hash = '#';
      }
    } else if (hash === 'profile') {
      this.setState({
        screen: 'profile'
      });
    } else if (hash === 'account') {
      this.setState({
        screen: 'account'
      });
    } else if (hash === 'forgot') {
      this.setState({
        screen: 'forgot'
      });
    } else if (hash === 'signup') {
      this.setState({
        screen: 'signup',
        password: '',
        password2: '',
        email: ''
      });
    } else {
      this.setState({
        screen: 'main'
      });
    }
  },
  login: function(username, password) {
    return this.props.aris.login(username, password, () => {
      this.updateLogin();
      if (((username != null) || (password != null)) && (this.props.aris.auth == null)) {
        alert('Incorrect username or password.');
      }
    });
  },
  logout: function() {
    window.location.hash = '#';
    this.props.aris.logout();
    return this.updateLogin();
  },
  updateLogin: function() {
    if (window.updateSiftrNav) window.updateSiftrNav();
    this.setState({
      auth: this.props.aris.auth,
      account_menu: false,
      password: '',
      password2: ''
    });
    if (this.props.aris.auth && window.location.pathname.match(/\blogin\b/)) {
      return window.location.href = '../discover/';
    } else {
      this.updateGames();
      return this.fetchUserPicture();
    }
  },
  getColorsAndThemes: function() {
    var i, l, m, results;
    for (i = l = 1; l <= 6; i = ++l) { // predefined schemes for now
      ((i) => {
        return this.props.aris.getColors({
          colors_id: i
        }, (result) => {
          if (result.returnCode === 0 && (result.data != null)) {
            this.setState((previousState, currentProps) => {
              return update(previousState, {
                colors: {
                  $merge: singleObj(i, result.data)
                }
              });
            });
          }
        });
      })(i);
    }
    results = [];
    for (i = m = 1; m <= 4; i = ++m) { // predefined schemes for now
      results.push(((i) => {
        return this.props.aris.getTheme({
          theme_id: i
        }, (result) => {
          if (result.returnCode === 0 && (result.data != null)) {
            this.setState((previousState, currentProps) => {
              return update(previousState, {
                themes: {
                  $merge: singleObj(i, result.data)
                }
              });
            });
          }
        });
      })(i));
    }
    return results;
  },
  fetchUserPicture: function() {
    if (this.props.aris.auth != null) {
      this.props.aris.call('media.getMedia', {
        media_id: this.props.aris.auth.media_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState({
            userPicture: result.data
          });
        }
      });
    } else {
      this.setState({
        userPicture: null
      });
    }
  },
  updateGames: function() {
    if (this.props.aris.auth != null) {
      return this.props.aris.getGamesForUser({}, (result) => {
        var game, games;
        if (result.returnCode === 0 && (result.data != null)) {
          games = (function() {
            var l, len, ref1, results;
            ref1 = result.data;
            results = [];
            for (l = 0, len = ref1.length; l < len; l++) {
              game = ref1[l];
              if (game.is_siftr) {
                results.push(game);
              }
            }
            return results;
          })();
          this.setState({
            games: games,
            tags: {},
            forms: {},
            notes: {}
          });
          this.applyHash();
          this.updateForms(games);
          this.updateQuests(games);
          this.updatePlaques(games);
          this.updateNotes(games);
        } else {
          this.setState({
            games: []
          });
        }
      });
    } else {
      this.setState({
        games: []
      });
    }
  },
  updateNotes: function(games) {
    return games.forEach((game) => {
      return this.props.aris.searchNotes({
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              notes: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          });
        }
      });
    });
  },
  updateForms: function(games, cb = (function() {})) {
    games.forEach((game) => {
      this.props.aris.getFieldsForGame({
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              forms: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
      this.props.aris.call('items.getItemsForGame', {
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              items: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
    });
  },
  updateQuests: function(games, cb = (function() {})) {
    return games.forEach((game) => {
      return this.props.aris.getQuestsForGame({
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              quests: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
    });
  },
  updatePlaques: function(games, cb = (function() {})) {
    games.forEach((game) => {
      this.props.aris.getPlaquesForGame({
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              plaques: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
      this.props.aris.call('instances.getInstancesForGame', {
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              instances: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
      this.props.aris.call('triggers.getTriggersForGame', {
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              triggers: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
      this.props.aris.call('events.getEventsForGame', {
        game_id: game.game_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState((previousState, currentProps) => {
            return update(previousState, {
              events: {
                $merge: singleObj(game.game_id, result.data)
              }
            });
          }, cb);
        }
      });
    });
  },
  // Adds the game to the known games list,
  // or updates an existing game if it shares the game ID.
  updateStateGame: function(newGame) {
    this.setState((previousState, currentProps) => {
      return update(previousState, {
        games: {
          $apply: (games) => {
            var foundOld, game, updated;
            foundOld = false;
            updated = (function() {
              var l, len, results;
              results = [];
              for (l = 0, len = games.length; l < len; l++) {
                game = games[l];
                if (game.game_id === newGame.game_id) {
                  foundOld = true;
                  results.push(newGame);
                } else {
                  results.push(game);
                }
              }
              return results;
            })();
            if (foundOld) {
              return updated;
            } else {
              return updated.concat([newGame]);
            }
          }
        }
      });
    });
  },
  handleSave: function() {
    return this.props.aris.updateGame(this.state.edit_game, (result) => {
      window.location.hash = '#';
      if (result.returnCode === 0 && (result.data != null)) {
        return this.updateStateGame(result.data);
      }
    });
  },
  uploadMedia: function(file, cb) {
    let fr = new FileReader;
    fr.onload = () => {
      const dataURL = fr.result;
      this.createNewIcon(dataURL, this.state.edit_game, (res) => {
        if (res && res.returnCode === 0 && res.data) {
          cb(res.data);
        };
      });
    };
    fr.readAsDataURL(file);
  },
  createNewIcon: function(dataURL, game, cb) {
    var base64, ext, extmap;
    if (dataURL == null) {
      cb(null);
      return;
    }
    extmap = {
      jpg: 'data:image/jpeg;base64,',
      png: 'data:image/png;base64,',
      gif: 'data:image/gif;base64,'
    };
    ext = null;
    base64 = null;
    for (var k in extmap) {
      var v = extmap[k];
      if (dataURL.slice(0, +(v.length - 1) + 1 || 9e9) === v) {
        ext = k;
        base64 = dataURL.slice(v.length);
      }
    }
    if ((ext != null) && (base64 != null)) {
      this.props.aris.call('media.createMedia', {
        game_id: game != null ? game.game_id : undefined,
        file_name: `upload.${ext}`,
        data: base64
      }, cb);
    } else {
      return cb(null);
    }
  },
  createQuest: function(cb) {
    const input = update(this.state.new_game, {
      game_id: {
        $set: this.state.edit_game.game_id,
      },
    });
    this.props.aris.call('quests.createStemportsQuest', input, (result) => {
      if (result.returnCode === 0) {
        cb && cb();
        this.updateQuests([this.state.edit_game]);
        this.updateForms([this.state.edit_game]);
        this.updatePlaques([this.state.edit_game]);
        this.updateNotes([this.state.edit_game]);
      }
    });
  },
  saveQuest: function(continuingSave = false) {
    if (!this.state.screen.match('quest')) return;
    if (!parseInt(this.state.new_game.quest_id)) return;

    if (this.state.savingQuest && !continuingSave) {
      this.pendingSave = true;
      return;
    }
    this.setState({savingQuest: true});
    const input = update(this.state.new_game, {
      game_id: {
        $set: this.state.edit_game.game_id,
      },
      do_update: {
        $set: true,
      },
      fields: (fields) => fields.map((field) => {
        if (field.noObservation) {
          return update(field, {sort_index: {$set: -1}});
        } else {
          return field;
        }
      }),
    });
    this.props.aris.call('quests.createStemportsQuest', input, (result) => {
      if (this.pendingSave) {
        this.pendingSave = false;
        this.saveQuest(true);
        return;
      }
      this.setState({savingQuest: false});
      if (result.returnCode === 0) {
        this.updateQuests([this.state.edit_game]);
        this.updateForms([this.state.edit_game]);
        this.updatePlaques([this.state.edit_game]);
        this.updateNotes([this.state.edit_game]);
      }
    });
  },
  createGame: function() {
    return this.props.aris.createGame(this.state.new_game, (result) => {
      if (result.returnCode === 0 && (result.data != null)) {
        window.location.hash = '#';
        let newGame = result.data;
        this.createNewIcon(this.state.new_icon, newGame, (result) => {
          if (result != null) {
            this.props.aris.call('games.updateGame', {
              game_id: newGame.game_id,
              icon_media_id: result.data.media_id
            }, ({
                data: game
              }) => {
              return this.updateStateGame(new Game(game));
            });
          }
        });
        this.updateStateGame(newGame);
        this.updateForms([newGame]);
        this.setState((previousState, currentProps) => {
          return update(previousState, {
            notes: {
              $merge: singleObj(newGame.game_id, [])
            },
            new_game: {
              $set: blankGame(),
            },
            new_categories: {
              $set: [
                {
                  category: '',
                  color: undefined
                }
              ]
            },
            new_icon: {
              $set: null
            },
            modal_game: {
              $set: newGame
            }
          });
        });
      }
    });
  },
  sendPasswordReset: function() {
    this.props.aris.call('users.requestForgotPasswordEmail', {
      user_name: this.state.username,
      email: this.state.email
    }, ({returnCode}) => {
      if (returnCode === 0) {
        alert('An email has been sent to that account (if it exists) to reset your password.');
        window.location.replace('#');
      }
    });
  },
  signup: function() {
    if (!this.state.email) {
      alert('Please enter your email address.');
    } else if (this.state.email.indexOf('@') < 0) {
      alert('Your email address is not valid.');
    } else if (!this.state.username) {
      alert('Please select a username.');
    } else if (!(this.state.password || this.state.password2)) {
      alert('Please enter a password.');
    } else if (this.state.password !== this.state.password2) {
      alert('Your passwords do not match.');
    } else {
      this.props.aris.call('users.createUser', {
        user_name: this.state.username,
        password: this.state.password,
        email: this.state.email
      }, ({returnCode, returnCodeDescription}) => {
        if (returnCode !== 0) {
          alert(`Couldn't create account: ${returnCodeDescription}`);
        } else {
          window.location.replace('#');
          this.login(this.state.username, this.state.password);
        }
      });
    }
  },
  continueAutosave: function() {
    var game;
    if ((game = this.autosavePending) != null) {
      this.autosavePending = null;
      this.props.aris.updateGame(game, onSuccess(() => {
        this.continueAutosave();
      }));
    } else {
      this.updateGames();
      this.setState({
        autosaving: false
      });
    }
  },
  autosave: function(game, autosave = true) {
    this.setState({
      edit_game: game
    });
    if (autosave) {
      this.autosavePending = game;
      if (!this.state.autosaving) {
        this.setState({
          autosaving: true
        });
        return this.continueAutosave();
      }
    }
  },
  render: function() {
    let breadcrumbs = [];
    if (this.state.auth != null) {
      breadcrumbs.push('<a href="#">Science Stations</a>');
      if (this.state.screen.match(/new/)) {
        breadcrumbs.push('New Science Station');
      } else if (this.state.screen.match(/quest/)) {
        breadcrumbs.push(`<a href="#edit${this.state.edit_game.game_id}">${this.state.edit_game.name}</a>`);
        breadcrumbs.push('New Quest');
      } else if (this.state.screen.match(/(edit|map)/)) {
        breadcrumbs.push(this.state.edit_game.name);
      }
    }
    document.getElementById('stemports-breadcrumbs').innerHTML = breadcrumbs.join(' &gt; ');

    var navBarActions;
    navBarActions = () => {
      child('div', () => {
        var ref1, ref2, ref3;
        if ((ref1 = this.state.screen) === 'new1' || ref1 === 'new2' || ref1 === 'quest1' || ref1 === 'quest2' || ref1 === 'quest3' || ref1 === 'quest4' || ref1 === 'quest5') {
          if (this.state.new_game && parseInt(this.state.new_game.quest_id)) {
            if (this.state.savingQuest) {
              raw('Saving…');
            }
          } else {
            child('a.create-cancel', {
              href: '#'
            }, () => {
              raw('Cancel');
            });
          }
        } else if ((ref2 = this.state.screen) === 'edit' || ref2 === 'map') {
          if (this.state.autosaving) {
            child('span.create-spinner', () => {
              child('span', () => {
                raw('saving');
              });
              child('img.spinny-saver', {
                src: '../assets/icons/spinny-saver.png'
              });
            });
          }
          child('a.create-cancel', {
            href: '#'
          }, () => {
            raw('Done');
          });
        } else if ((ref3 = this.state.screen) === 'categories' || ref3 === 'form') {
          child('a.create-cancel', {
            href: '#'
          }, () => {
            raw('Done');
          });
        }
      });
    };
    return make(`div.topDiv.accountMenu${(this.state.account_menu ? 'Open' : 'Closed')}`, () => {
      var game;
      child('div.nav-bar.desktop-nav-bar', () => {
        var ref1, ref2;
        if ((ref1 = this.state.screen) === 'new1' || ref1 === 'new2' || ref1 === 'quest1' || ref1 === 'quest2' || ref1 === 'quest3' || ref1 === 'quest4' || ref1 === 'quest5') {
          return child('div.nav-bar-line', () => {
            child('div', () => {
              var selectTab;
              selectTab = (step) => {
                if (this.state.screen === step) {
                  return '.create-step-tab-selected';
                } else {
                  return '';
                }
              };
              if (this.state.screen === 'new1' || this.state.screen === 'new2') {
                child(`a.create-step-tab${selectTab('new1')}`, {
                  href: '#new1'
                }, () => {
                  raw('Overview');
                });
                child(`a.create-step-tab${selectTab('new2')}`, {
                  href: '#new2'
                }, () => {
                  raw('Location');
                });
              } else {
                child(`a.create-step-tab${selectTab('quest1')}`, {
                  href: '#quest1'
                }, () => {
                  raw('Overview');
                });
                child(`a.create-step-tab${selectTab('quest2')}`, {
                  href: '#quest2'
                }, () => {
                  raw('Onboarding');
                });
                child(`a.create-step-tab${selectTab('quest3')}`, {
                  href: '#quest3'
                }, () => {
                  raw('Observation');
                });
                child(`a.create-step-tab${selectTab('quest4')}`, {
                  href: '#quest4'
                }, () => {
                  raw('Field Notes');
                });
                child(`a.create-step-tab${selectTab('quest5')}`, {
                  href: '#quest5'
                }, () => {
                  raw('Tour Stops');
                });
              }
            });
            return navBarActions();
          });
        } else if ((ref2 = this.state.screen) === 'edit' || ref2 === 'map' || ref2 === 'form') {
          return child('div.nav-bar-line', () => {
            child('div', () => {
              var selectTab;
              selectTab = (step) => {
                if (this.state.screen === step) {
                  return '.create-step-tab-selected';
                } else {
                  return '';
                }
              };
              child(`a.create-step-tab${selectTab('edit')}`, {
                href: '#edit' + this.state.edit_game.game_id
              }, () => {
                raw('Settings');
              });
              child(`a.create-step-tab${selectTab('map')}`, {
                href: '#map' + this.state.edit_game.game_id
              }, () => {
                raw('Location');
              });
            });
            return navBarActions();
          });
        }
      });
      child('div.nav-bar.mobile-nav-bar', () => {
        return child('div.nav-bar-line', () => {
          child('div', () => {
          });
          return navBarActions();
        });
      });
      child('div#the-content', () => {
        var fields, innerNav;
        if (this.state.auth != null) {
          innerNav = () => {
            child(InnerNav, {
              screen: this.state.screen,
              userPicture: this.state.userPicture,
              auth: this.state.auth,
              logout: this.logout
            });
          };
          switch (this.state.screen) {
            case 'profile':
              innerNav();
              return child(ProfileSettings, {
                aris: this.props.aris,
                auth: this.state.auth,
                userPicture: this.state.userPicture,
                onSave: (obj) => {
                  var useMediaID;
                  useMediaID = (media_id) => {
                    this.props.aris.call('users.updateUser', {
                      user_id: this.props.aris.auth.user_id,
                      display_name: obj.display_name,
                      bio: obj.bio,
                      url: obj.url,
                      media_id: media_id
                    }, ({returnCode, returnCodeDescription}) => {
                      if (returnCode === 0) {
                        this.login(undefined, undefined);
                        window.location.replace('#');
                      } else {
                        alert(`Couldn't save your account details: ${returnCodeDescription}`);
                      }
                    });
                  };
                  if (obj.new_icon != null) {
                    return this.createNewIcon(obj.new_icon, null, (result) => {
                      if (result != null) {
                        useMediaID(result.data.media_id);
                      } else {
                        alert("Your user picture is not of a supported type.");
                      }
                    });
                  } else {
                    useMediaID(null);
                  }
                }
              });
            case 'account':
              innerNav();
              return child(AccountSettings, {
                aris: this.props.aris,
                auth: this.state.auth,
                onSave: (obj) => {
                  this.props.aris.call('users.updateUser', {
                    user_id: this.props.aris.auth.user_id,
                    email: obj.email
                  }, ({returnCode, returnCodeDescription}) => {
                    if (returnCode === 0) {
                      if (obj.new_password) {
                        this.props.aris.call('users.changePassword', {
                          user_name: obj.user_name,
                          old_password: obj.old_password,
                          new_password: obj.new_password
                        }, ({returnCode, returnCodeDescription}) => {
                          if (returnCode === 0) {
                            this.logout();
                            this.login(obj.user_name, obj.new_password);
                          } else {
                            alert(`Couldn't change your password: ${returnCodeDescription}`);
                          }
                        });
                      } else {
                        this.login(undefined, undefined);
                        window.location.replace('#');
                      }
                    } else {
                      alert(`Couldn't save your account details: ${returnCodeDescription}`);
                    }
                  });
                }
              });
            case 'edit':
              return child(EditOverview, {
                game: this.state.edit_game,
                onChange: this.autosave/*.bind(this)*/,
                mobileMapIsOpen: this.state.mobile_map_is_open,
                openMobileMap: () => {
                  this.setState({
                    mobile_map_is_open: true
                  });
                  return setTimeout(() => {
                    return window.dispatchEvent(new Event('resize'));
                  }, 250);
                },
                closeMobileMap: () => {
                  this.setState({
                    mobile_map_is_open: false
                  });
                }
              });
            case 'map':
              return child(StationLocation, {
                editing: true,
                game: this.state.edit_game,
                onChange: (new_game) => {
                  this.autosave(new_game);
                },
              });
            case 'new1':
              return child(NewOverview, {
                game: this.state.new_game,
                icon: this.state.new_icon,
                onChange: (new_game) => {
                  this.setState({new_game});
                },
                onIconChange: (new_icon) => {
                  this.setState({new_icon});
                },
                scienceStation: true,
              });
            case 'new2':
              return child(StationLocation, {
                game: this.state.new_game,
                onChange: (new_game) => {
                  this.setState({new_game});
                },
                onCreate: this.createGame,
              });
            case 'quest1':
              return child(NewOverview, {
                game: this.state.new_game,
                icon: this.state.new_icon,
                onChange: (new_game) => {
                  this.setState({new_game}, () => this.saveQuest());
                },
                onIconChange: (new_icon) => {
                  this.setState({new_icon});
                },
                uploadMedia: this.uploadMedia/*.bind(this)*/,
                aris: this.props.aris,
              });
            case 'quest2':
              return child(Onboarding, {
                game: this.state.new_game,
                uploadMedia: this.uploadMedia/*.bind(this)*/,
                onChange: (new_game) => {
                  this.setState({new_game}, () => this.saveQuest());
                },
                aris: this.props.aris,
              });
            case 'quest3':
              return child(FormEditor, {
                editing: false,
                game: this.state.new_game,
                categories: this.state.new_categories,
                colors: this.state.colors,
                onChange: (new_game) => {
                  this.setState({new_game}, () => this.saveQuest());
                },
                onChangeCategories: (new_categories) => {
                  this.setState({new_categories});
                },
              });
            case 'quest4':
              return child(FieldNotes, {
                game: this.state.new_game,
                onChange: (new_game) => {
                  this.setState({new_game}, () => this.saveQuest());
                },
                aris: this.props.aris,
                uploadMedia: this.uploadMedia/*.bind(this)*/,
              });
            case 'quest5':
              return child(MapOptions, {
                game: this.state.new_game,
                colors: this.state.colors,
                themes: this.state.themes,
                onChange: (new_game) => {
                  this.setState({new_game}, () => this.saveQuest());
                },
                uploadMedia: this.uploadMedia/*.bind(this)*/,
                aris: this.props.aris,
              });
            default:
              return child('div', () => {
                innerNav();
                child(SiftrList, {
                  updateStateGame: this.updateStateGame,
                  aris: this.props.aris,
                  games: this.state.games,
                  colors: this.state.colors,
                  notes: this.state.notes,
                  quests: this.state.quests,
                  downloadCSV: (game) => {
                    this.props.aris.call('notes.siftrCSV', {
                      game_id: game.game_id
                    }, ({data, returnCode, returnCodeDescription}) => {
                      if (returnCode === 0) {
                        if (data.indexOf("\r") === -1) {
                          data = data.split("\n").join("\r\n");
                        }
                        const element = document.createElement('a');
                        element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(data));
                        element.setAttribute('download', 'Siftr - ' + game.name + '.csv');
                        element.style.display = 'none';
                        document.body.appendChild(element);
                        element.click();
                        document.body.removeChild(element);
                      }
                    });
                  },
                  onDelete: (game) => {
                    this.props.aris.call('games.deleteGame', {
                      game_id: game.game_id
                    }, ({returnCode, returnCodeDescription}) => {
                      if (returnCode === 0) {
                        this.updateGames();
                      } else {
                        alert(`There was an error deleting your Siftr: ${returnCodeDescription}`);
                      }
                    });
                  },
                  startNewQuest: (game) => {
                    const quest = update(blankGame(), {
                      name: {$set: 'New Quest'},
                    });
                    this.setState({new_game: quest, edit_game: game}, () => {
                      this.createQuest(() => {
                        // TODO open the new quest
                      });
                    });
                  },
                  deleteQuest: (quest) => {
                    if (confirm(`Delete the quest "${quest.name}"?`)) {
                      this.props.aris.call('quests.deleteQuest', {
                        quest_id: quest.quest_id,
                      }, () => {
                        this.updateQuests([quest]); // passing because it has the game_id
                      });
                    }
                  },
                  editOrCopyQuest: (game, quest, copy) => {
                    const fields = this.state.forms[game.game_id].filter(field =>
                      parseInt(field.quest_id) === parseInt(quest.quest_id)
                    ).map(field => update(field, {
                      noFieldNote: {$set: field.guide == null},
                      noObservation: {$set: parseInt(field.sort_index) < 0},
                      options: (opts) => opts.map(opt => {
                        const item = this.state.items[game.game_id].find(item =>
                          parseInt(item.item_id) === parseInt(opt.remnant_id)
                        );
                        if (item) {
                          return update(opt, {
                            description: {
                              $set: item.description,
                            },
                            media_id: {
                              $set: item.media_id,
                            },
                          });
                        } else {
                          return opt;
                        }
                      }),
                    }));
                    const quest_data = {
                      name: copy ? quest.name + ' (Copy)' : quest.name,
                      quest_id: copy ? null : quest.quest_id,
                      description: quest.description,
                      colors_id: 1,
                      theme_id: 1,
                      map_show_labels: true,
                      map_show_roads: true,
                      map_type: 'STREET',
                      zoom: 12,
                      is_siftr: true,
                      type: 'ANYWHERE',
                      latitude: game.latitude,
                      longitude: game.longitude,
                      fields: fields,
                      tutorial_1_title: quest.tutorial_1_title,
                      tutorial_1: quest.tutorial_1,
                      tutorial_1_media_id: quest.tutorial_1_media_id,
                      tutorial_2_title: quest.tutorial_2_title,
                      tutorial_2: quest.tutorial_2,
                      tutorial_2_media_id: quest.tutorial_2_media_id,
                      tutorial_3_title: quest.tutorial_3_title,
                      tutorial_3: quest.tutorial_3,
                      tutorial_3_media_id: quest.tutorial_3_media_id,
                      active_icon_media_id: quest.active_icon_media_id,
                      plaques: this.state.plaques[game.game_id].filter(plaque =>
                        parseInt(plaque.quest_id) === parseInt(quest.quest_id)
                      ).map(plaque => {
                        const events = this.state.events[game.game_id].filter(event =>
                          parseInt(event.event_package_id) === parseInt(plaque.event_package_id)
                        );
                        const instance = this.state.instances[game.game_id].find(instance =>
                          instance.object_type === 'PLAQUE' &&
                          parseInt(instance.object_id) === parseInt(plaque.plaque_id)
                        );
                        const trigger = this.state.triggers[game.game_id].find(trigger =>
                          parseInt(trigger.instance_id) === parseInt(instance.instance_id)
                        );
                        return update(plaque, {
                          latitude: {$set: trigger.latitude},
                          longitude: {$set: trigger.longitude},
                          fieldNotes: {
                            $set: events.filter(e =>
                              e.event === 'GIVE_ITEM'
                            ).map(e => {
                              const item_id = parseInt(e.content_id);
                              let option = null;
                              this.state.forms[game.game_id].forEach(field => {
                                field.options && field.options.forEach(opt => {
                                  if (parseInt(opt.remnant_id) === item_id) {
                                    option = opt;
                                  }
                                });
                              });
                              return option && parseInt(option.field_option_id);
                            }).filter(x => x),
                          },
                        });
                      }),
                    };
                    this.setState({edit_game: game, new_game: quest_data}, () => {
                      if (copy) {
                        this.createQuest();
                      } else {
                        window.location.hash = '#quest1';
                      }
                    });
                  },
                });
              });
          }
        } else {
          switch (this.state.screen) {
            case 'forgot':
              return child('div.loginForm', () => {
                child('p', () => {
                  raw('Enter your username ');
                  child('b', () => {
                    raw('or');
                  });
                  raw(' email to reset your password.');
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'text',
                    placeholder: 'Username',
                    value: (ref1 = this.state.username) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        username: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        this.sendPasswordReset();
                      }
                    }
                  });
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'text',
                    placeholder: 'Email',
                    value: (ref1 = this.state.email) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        email: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.sendPasswordReset();
                      }
                    }
                  });
                });
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.sendPasswordReset();
                    }
                  });
                  return child('div.login-button', () => {
                    raw('SEND EMAIL');
                  });
                });
                return child('a', {
                  href: '#'
                }, () => {
                  return child('div.login-button', () => {
                    raw('BACK');
                  });
                });
              });
            case 'signup':
              return child('div.loginForm', () => {
                child('p', () => {
                  raw('Create a new STEMports account');
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'text',
                    placeholder: 'Email',
                    value: (ref1 = this.state.email) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        email: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.signup();
                      }
                    }
                  });
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'text',
                    placeholder: 'Username',
                    value: (ref1 = this.state.username) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        username: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.signup();
                      }
                    }
                  });
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'password',
                    placeholder: 'Password',
                    value: (ref1 = this.state.password) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        password: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.signup();
                      }
                    }
                  });
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'password',
                    placeholder: 'Repeat password',
                    value: (ref1 = this.state.password2) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        password2: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.signup();
                      }
                    }
                  });
                });
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.signup();
                    }
                  });
                  return child('div.login-button', () => {
                    raw('CREATE ACCOUNT');
                  });
                });
                return child('a', {
                  href: '#'
                }, () => {
                  return child('div.login-button', () => {
                    raw('BACK');
                  });
                });
              });
            default:
              return child('div.loginForm', () => {
                child('p', () => {
                  raw('Login with a STEMports account');
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'text',
                    placeholder: 'Username',
                    value: (ref1 = this.state.username) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        username: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.login(this.state.username, this.state.password);
                      }
                    }
                  });
                });
                child('p', () => {
                  var ref1;
                  return child('input.full-width-input', {
                    autoCapitalize: 'off',
                    autoCorrect: 'off',
                    type: 'password',
                    placeholder: 'Password',
                    value: (ref1 = this.state.password) != null ? ref1 : '',
                    onChange: (e) => {
                      this.setState({
                        password: e.target.value
                      });
                    },
                    onKeyDown: (e) => {
                      if (e.keyCode === 13) {
                        return this.login(this.state.username, this.state.password);
                      }
                    }
                  });
                });
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.login(this.state.username, this.state.password);
                    }
                  });
                  return child('div.login-button', () => {
                    raw('LOGIN');
                  });
                });
                child('a', {
                  href: '#signup'
                }, () => {
                  return child('div.login-button', () => {
                    raw('CREATE ACCOUNT');
                  });
                });
                return child('a', {
                  href: '#forgot'
                }, () => {
                  return child('div.login-button', () => {
                    raw('FORGOT PASSWORD?');
                  });
                });
              });
          }
        }
      });
      if (this.state.modal_game != null) {
        game = this.state.modal_game;
        return child('div.newGameFixedBox', () => {
          child('a.newGameCurtain', {
            href: '#',
            onClick: (e) => {
              e.preventDefault();
              this.setState({
                modal_game: null
              });
            }
          });
          return child('div.newGameModal', () => {
            ({
              onClick: (e) => {
                return e.stopPropagation();
              }
            });
            child('h1', () => {
              raw('Congrats! Your Stemports station has been created.');
            });
          });
        });
      }
      if (this.state.modal_quest != null) {
        return child('div.newGameFixedBox', () => {
          child('a.newGameCurtain', {
            href: '#',
            onClick: (e) => {
              e.preventDefault();
              this.setState({
                modal_quest: null
              });
            }
          });
          return child('div.newGameModal', () => {
            ({
              onClick: (e) => {
                return e.stopPropagation();
              }
            });
            child('h1', () => {
              raw('Congrats! Your Stemports quest has been created.');
            });
          });
        });
      }
    });
  }
});

const EditOverview = createClass({
  displayName: 'EditOverview',
  render: function() {
    return make('div.newStepBox', () => {
      child('div.newStep1', () => {
        child('div.newStep1LeftColumn', () => {
          return child('form', () => {
            var currentLink, hidden, moderated;
            child('h2', () => {
              raw(this.props.game.name);
            });
            child('label', () => {
              var ref1;
              child('h4', () => {
                raw('Science Station Title');
              });
              return child('input.full-width-input', {
                type: 'text',
                value: (ref1 = this.props.game.name) != null ? ref1 : '',
                onChange: (e) => {
                  var game;
                  game = update(this.props.game, {
                    name: {
                      $set: e.target.value
                    }
                  });
                  return this.props.onChange(game, false);
                },
                onBlur: () => {
                  return this.props.onChange(this.props.game, true);
                }
              });
            });
            child('label', () => {
              var ref1;
              child('h4', () => {
                raw('Science Station Summary');
              });
              return child('textarea.full-width-textarea', {
                value: (ref1 = this.props.game.description) != null ? ref1 : '',
                onChange: (e) => {
                  var game;
                  game = update(this.props.game, {
                    description: {
                      $set: e.target.value
                    }
                  });
                  return this.props.onChange(game, false);
                },
                onBlur: () => {
                  return this.props.onChange(this.props.game, true);
                }
              });
            });
            child('h2', () => {
              raw('SHARE');
            });
            child('h4', () => {
              raw('PRIVACY');
            });
            hidden = !this.props.game.published;
            child(`a.form-multi-option.form-multi-option-${(hidden ? 'on' : 'off')}`, {
              href: '#'
            }, () => {
              props({
                onClick: (e) => {
                  e.preventDefault();
                  return this.props.onChange(update(this.props.game, {
                    published: {
                      $set: hidden
                    }
                  }));
                }
              });
              child('span.form-multi-option-text', () => {
                raw('Hide from other players');
              });
              child('span.form-multi-option-switch', () => {
                child('span.form-multi-option-ball');
              });
            });
          });
        });
        return child('div.newStep1RightColumn');
      });
      return child('div.bottom-step-buttons', () => {
        child('div');
        return child('a', {
          href: '#map' + this.props.game.game_id
        }, () => {
          return child('div.newNextButton', () => {
            raw('map >');
          });
        });
      });
    });
  }
});

const Onboarding = createClass({
  displayName: 'Onboarding',
  render: function() {
    return (
      <div className="newStepBox">
        <div className="newStep1">
          <div className="newStep1Column newStep1LeftColumn">
            <div>
              <h1>Player Onboarding Setup:</h1>
              {
                ['1', '2', '3'].map(i =>
                  <div key={i}>
                    <label>
                      <p>Panel {i} Title</p>
                      <input
                        className="full-width-input"
                        type="text"
                        value={this.props.game[`tutorial_${i}_title`] || ""}
                        onChange={e => this.props.onChange(update(this.props.game, {
                          [`tutorial_${i}_title`]: {
                            $set: e.target.value,
                          },
                        }))}
                      />
                    </label>
                    <label>
                      <p>Panel {i} Description</p>
                      <textarea className="full-width-textarea"
                        value={this.props.game[`tutorial_${i}`] || ""}
                        onChange={e => this.props.onChange(update(this.props.game, {
                          [`tutorial_${i}`]: {
                            $set: e.target.value,
                          },
                        }))}
                      />
                    </label>
                    <label>
                      <p>Panel {i} Image</p>
                      <MediaSelect
                        media={this.props.game[`tutorial_${i}_media`]}
                        media_id={this.props.game[`tutorial_${i}_media_id`]}
                        uploadMedia={this.props.uploadMedia}
                        game={this.props.game}
                        aris={this.props.aris}
                        applyMedia={(media) => {
                          this.props.onChange(update(this.props.game, {
                            [`tutorial_${i}_media`]: {
                              $set: media, // includes url for displaying
                            },
                            [`tutorial_${i}_media_id`]: {
                              $set: media.media_id, // to actually set in database
                            },
                          }));
                        }}
                      />
                    </label>
                    <hr />
                  </div>
                )
              }
            </div>
          </div>
          <div className="newStep1Column newStep1RightColumn">
          </div>
        </div>
        <div className="bottom-step-buttons">
          <a href="#quest1">
            <div className="newPrevButton">
              {'< overview'}
            </div>
          </a>
          <a href="#quest3">
            <div className="newNextButton">
              {'observation >'}
            </div>
          </a>
        </div>
      </div>
    );
  },
});

const NewOverview = createClass({
  displayName: 'NewOverview',
  render: function() {
    return make('div.newStepBox', () => {
      child('div.newStep1', () => {
        child('div.newStep1Column.newStep1LeftColumn', () => {
          return child('div', () => {
            child('label', () => {
              var ref1;
              child('p', () => {
                raw(this.props.scienceStation ? 'Science Station Title' : 'Quest Title');
              });
              return child('input.full-width-input', {
                ref: 'name',
                type: 'text',
                value: (ref1 = this.props.game.name) != null ? ref1 : '',
                onChange: this.handleChange
              });
            });
            child('label', () => {
              child('p', () => {
                raw(this.props.scienceStation ? 'Station Thumbnail' : 'Quest Thumbnail');
              });
              if (this.props.scienceStation) {
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.selectImage();
                    }
                  });
                  return child(`div.siftr-icon-area.siftr-icon-${(this.props.icon != null ? 'filled' : 'empty')}`, () => {
                    if (this.props.icon != null) {
                      props({
                        style: {
                          backgroundImage: `url(${this.props.icon})`
                        }
                      });
                    } else {
                      child('div.siftr-icon-gray-circle');
                      child('h3', () => {
                        raw('Drag an image here or click to browse.');
                      });
                      child('p', () => {
                        return child('i', () => {
                          raw('200px by 200px recommended');
                        });
                      });
                    }
                    return props({
                      onDragOver: (e) => {
                        e.stopPropagation();
                        return e.preventDefault();
                      },
                      onDrop: (e) => {
                        var file, l, len, ref1;
                        e.stopPropagation();
                        e.preventDefault();
                        ref1 = e.dataTransfer.files;
                        for (l = 0, len = ref1.length; l < len; l++) {
                          file = ref1[l];
                          this.loadImageFile(file);
                          break;
                        }
                      }
                    });
                  });
                });
              } else {
                child(MediaSelect, {
                  media: this.props.game.active_icon_media,
                  media_id: this.props.game.active_icon_media_id,
                  uploadMedia: this.props.uploadMedia,
                  game: this.props.game,
                  aris: this.props.aris,
                  applyMedia: (media) => {
                    this.props.onChange(update(this.props.game, {
                      active_icon_media: {
                        $set: media, // includes url for displaying
                      },
                      active_icon_media_id: {
                        $set: media.media_id, // to actually set in database
                      },
                    }));
                  },
                });
              }
            });
            child('label', () => {
              var ref1;
              child('p', () => {
                raw(this.props.scienceStation ? 'Station Summary' : 'Quest Summary');
              });
              return child('textarea.full-width-textarea', {
                ref: 'description',
                value: (ref1 = this.props.game.description) != null ? ref1 : '',
                onChange: this.handleChange
              });
            });
            if (this.props.scienceStation) {
              const hidden = !this.props.game.published;
              child(`a.form-multi-option.form-multi-option-${(hidden ? 'on' : 'off')}`, {
                href: '#'
              }, () => {
                props({
                  onClick: (e) => {
                    e.preventDefault();
                    return this.props.onChange(update(this.props.game, {
                      published: {
                        $set: hidden
                      }
                    }));
                  }
                });
                child('span.form-multi-option-text', () => {
                  raw('Hide from other players');
                });
                child('span.form-multi-option-switch', () => {
                  child('span.form-multi-option-ball');
                });
              });
            }
          });
        });
        return child('div.newStep1Column.newStep1RightColumn');
      });
      return child('div.bottom-step-buttons', () => {
        child('div');
        return child('a', {
          href: this.props.scienceStation ? '#new2' : '#quest2',
        }, () => {
          props({
            onClick: (e) => {
              if (!hasNameDesc(this.props.game)) {
                alert(`Please enter a name and user instructions for your ${this.props.scienceStation ? 'science station' : 'quest'}.`);
                e.preventDefault();
                return;
              }
            }
          });
          child('div.newNextButton', () => {
            if (this.props.scienceStation) {
              raw('location >');
            } else {
              raw('onboarding >');
            }
          });
        });
      });
    });
  },
  selectImage: function() {
    var input;
    input = document.createElement('input');
    input.type = 'file';
    input.onchange = (e) => {
      return this.loadImageFile(e.target.files[0]);
    };
    return input.click();
  },
  loadImageFile: function(file) {
    var fr;
    fr = new FileReader;
    fr.onload = () => {
      return this.props.onIconChange(fr.result);
    };
    return fr.readAsDataURL(file);
  },
  handleChange: function() {
    var game;
    game = update(this.props.game, {
      name: {
        $set: this.refs.name.value
      },
      description: {
        $set: this.refs.description.value
      }
    });
    return this.props.onChange(game);
  }
});

const makeArrow = (dir, enabled, wrap) => {
  const src = `../assets/icons/arrow-${dir}.png`;
  if (enabled) {
    wrap(() => {
      child('img.sort-arrow', {src});
    });
  } else {
    child('img.sort-arrow.sort-arrow-disabled', {src});
  }
};

const CategoryRow = createClass({
  getInitialState: function() {
    return {
    };
  },
  updateOption: function(opt) {
    var opts;
    opts = this.props.options.slice(0);
    opts.splice(this.props.i, 1, opt);
    return this.props.updateOptions(opts);
  },
  render: function() {
    var colors, i, j, o, options;
    o = this.props.o;
    i = this.props.i;
    options = this.props.options;
    colors = (function() {
      var l, results;
      results = [];
      for (j = l = 1; l <= 8; j = ++l) {
        results.push(this.props.colors[this.props.game.colors_id || 1][`tag_${j}`]);
      }
      return results;
    }).call(this);
    return make('div', () => {
      child('li.field-option-row', () => {
        var color;
        makeArrow('up', i !== 0, (f) => {
          child('a', {
            href: '#',
            onClick: ((e) => {
              var indexes;
              e.preventDefault();
              indexes = (function() {
                var l, ref1, results;
                results = [];
                for (j = l = 0, ref1 = options.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); j = 0 <= ref1 ? ++l : --l) {
                  if (j === i) {
                    results.push(j - 1);
                  } else if (j === i - 1) {
                    results.push(j + 1);
                  } else {
                    results.push(j);
                  }
                }
                return results;
              })();
              return this.props.reorderFieldOptions(indexes);
            })
          }, f);
        });
        makeArrow('down', i !== options.length - 1, (f) => {
          return child('a', {
            href: '#',
            onClick: ((e) => {
              var indexes;
              e.preventDefault();
              indexes = (function() {
                var l, ref1, results;
                results = [];
                for (j = l = 0, ref1 = options.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); j = 0 <= ref1 ? ++l : --l) {
                  if (j === i) {
                    results.push(j + 1);
                  } else if (j === i + 1) {
                    results.push(j - 1);
                  } else {
                    results.push(j);
                  }
                }
                return results;
              })();
              return this.props.reorderFieldOptions(indexes);
            })
          }, f);
        });
        if (this.props.editing) {
          child('input', {
            type: 'text',
            defaultValue: o.option,
            onBlur: (e) => {
              if (this.props.editingCategory) {
                this.props.updateCategory({
                  tag_id: o.field_option_id,
                  name: e.target.value
                });
              } else {
                this.props.updateFieldOption({
                  field_option: o,
                  option: e.target.value
                });
              }
            }
          });
        } else {
          child('input', {
            type: 'text',
            value: o.option,
            onChange: (e) => {
              this.updateOption(update(o, {
                option: {
                  $set: e.target.value
                }
              }));
            }
          });
        }
        if (options.length > 1) {
          return child('a', {
            href: '#',
            onClick: ((e) => {
              var opts;
              e.preventDefault();
              if (this.props.editing) {
                return this.props.startDeletingOption(o);
              } else {
                opts = options.slice(0);
                opts.splice(i, 1);
                return this.props.updateOptions(opts);
              }
            })
          }, () => {
            return child('img.deletefield', {
              src: '../assets/icons/deletefield.png'
            });
          });
        }
      });
    });
  }
});

const NumberInput = createClass({
  render: function() {
    return make('div.number-input-label', () => {
      child('span', () => {
        raw(this.props.label);
      });
      child('input', {
        type: 'number',
        value: this.props.value,
        step: 0.00000001,
        onChange: (e) => {
          this.props.onChangeValue(e.target.value);
        },
      });
    });
  },
});

const ColorNumberInput = createClass({
  getInitialState: function() {
    return {
      colorsOpen: false
    };
  },
  render: function() {
    const colors = [1, 2, 3, 4, 5, 6, 7, 8].map((i) =>
      this.props.colors[this.props.game.colors_id || 1][`tag_${i}`]
    );
    return make('div', () => {
      child('li.field-option-row', () => {
        child(NumberInput, {
          label: this.props.label,
          value: this.props.value,
          onChangeValue: this.props.onChangeValue,
        });
        child('a', {
          href: '#'
        }, () => {
          props({
            onClick: (e) => {
              e.preventDefault();
              this.setState({
                colorsOpen: !this.state.colorsOpen
              });
            }
          });
          return child('div.category-color-dot', {
            style: {
              backgroundColor: this.props.color
            }
          });
        });
      });
      if (this.state.colorsOpen) {
        return child('li.category-color-dots', () => {
          return colors.forEach((color) => {
            return child('a', {
              href: '#'
            }, () => {
              props({
                onClick: (e) => {
                  e.preventDefault();
                  this.props.onChangeColor(color);
                  this.setState({
                    colorsOpen: false
                  });
                }
              });
              return child('div.category-color-dot', {
                style: {
                  backgroundColor: color
                }
              });
            });
          });
        });
      }
    });
  },
});

const FormEditor = createClass({
  displayName: 'FormEditor',
  getInitialState: function() {
    return {
      editingIndex: null,
      editingField: null,
      deletingOption: null,
      showFieldTypes: false
    };
  },
  reorderFields: function(indexes) {
    var fixIndex, i;
    fixIndex = () => {
      if ((this.state.editingIndex != null) && this.state.editingIndex >= 0) {
        this.setState({
          editingIndex: indexes[this.state.editingIndex]
        });
      }
    };
    if (this.props.editing) {
      return this.props.reorderFields(indexes, fixIndex);
    } else {
      fixIndex();
      return this.props.onChange(update(this.props.game, {
        fields: {
          $set: (function() {
            var l, ref1, results;
            results = [];
            for (i = l = 0, ref1 = indexes.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); i = 0 <= ref1 ? ++l : --l) {
              results.push(this.props.game.fields[indexes[i]]);
            }
            return results;
          }).call(this)
        }
      }));
    }
  },
  reorderFieldOptions: function(indexes, cb) {
    var i;
    if (this.props.editing) {
      if (this.state.editingIndex < 0) {
        return this.props.reorderCategories(indexes, cb);
      } else {
        return this.props.reorderFieldOptions(this.state.editingField, indexes, cb);
      }
    } else {
      this.setState({
        editingField: update(this.state.editingField, {
          options: {
            $set: (function() {
              var l, ref1, results;
              results = [];
              for (i = l = 0, ref1 = indexes.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); i = 0 <= ref1 ? ++l : --l) {
                results.push(this.state.editingField.options[indexes[i]]);
              }
              return results;
            }).call(this)
          }
        })
      });
    }
  },
  getPropsFields: function(props = this.props) {
    var ref1, ref2;
    if (props.editing) {
      return (ref1 = props.fields) != null ? ref1 : [];
    } else {
      return (ref2 = props.game.fields) != null ? ref2 : [];
    }
  },
  componentWillReceiveProps: function(nextProps) {
    var index, nextFields, thisFields;
    thisFields = this.getPropsFields(this.props);
    nextFields = this.getPropsFields(nextProps);
    if (thisFields.length + 1 === nextFields.length) {
      index = nextFields.length - 1;
      this.setState({
        editingIndex: index,
        editingField: nextFields[index],
        deletingOption: null
      });
    }
  },
  render: function() {
    return make('div.newStepBox', () => {
      var categoryOptions, fields;
      fields = this.getPropsFields();
      categoryOptions = () => {
        var cat, i, l, len, len1, m, ref1, ref2, ref3, results, results1;
        if (this.props.editing) {
          ref2 = (ref1 = this.props.categories) != null ? ref1 : [];
          results = [];
          for (l = 0, len = ref2.length; l < len; l++) {
            cat = ref2[l];
            results.push({
              option: cat.tag,
              field_option_id: cat.tag_id,
              color: cat.color
            });
          }
          return results;
        } else {
          ref3 = this.props.categories;
          results1 = [];
          for (i = m = 0, len1 = ref3.length; m < len1; i = ++m) {
            cat = ref3[i];
            results1.push({
              option: cat.category,
              field_option_id: i,
              color: cat.color
            });
          }
          return results1;
        }
      };
      child('div.newStep4', () => {
        child('div.newStep4Fields', () => {
          const divFormFieldRow = (i) => {
            var row;
            row = 'div.form-field-row';
            if (i === this.state.editingIndex) {
              row += '.form-field-row-selected';
            }
            return row;
          };
          fields.forEach((field, i) => {
            return child(divFormFieldRow(i), {
              key: field.field_id
            }, () => {
              child('div.form-field-icon', () => {
                return child('img', {
                  src: `../assets/icons/form-${field.field_type}.png`
                });
              });
              child('a.form-field-name', {
                href: '#',
                onClick: (e) => {
                  e.preventDefault();
                  this.setState({
                    editingField: field,
                    editingIndex: i,
                    deletingOption: null
                  });
                }
              }, () => {
                raw(field.label || 'Unnamed task');
                if (field.noObservation) {
                  raw(' ');
                  child('i', () => raw('[only field notes]'));
                } else {
                  if (field.required) {
                    raw(' ');
                    return child('span.required-star', () => {
                      raw('*');
                    });
                  }
                }
              });
              if (field.field_id === this.props.game.field_id_preview || field.field_id === this.props.game.field_id_caption || field.useOnCards) {
                child('img.role-icon', {
                  src: "../assets/icons/role-card.png"
                });
              } else if (field.field_id === this.props.game.field_id_pin || field.useAsPin) {
                child('img.role-icon', {
                  src: "../assets/icons/role-pin.png"
                });
              }
              return child('div.form-field-x', () => {
                makeArrow('up', i !== 0, (f) => {
                  return child('a', {
                    href: '#',
                    onClick: ((e) => {
                      var j;
                      e.preventDefault();
                      e.stopPropagation();
                      return this.reorderFields((function() {
                        var l, ref1, results;
                        results = [];
                        for (j = l = 0, ref1 = fields.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); j = 0 <= ref1 ? ++l : --l) {
                          if (j === i) {
                            results.push(j - 1);
                          } else if (j === i - 1) {
                            results.push(j + 1);
                          } else {
                            results.push(j);
                          }
                        }
                        return results;
                      })());
                    })
                  }, f);
                });
                makeArrow('down', i !== fields.length - 1, (f) => {
                  return child('a', {
                    href: '#',
                    onClick: ((e) => {
                      var j;
                      e.preventDefault();
                      e.stopPropagation();
                      return this.reorderFields((function() {
                        var l, ref1, results;
                        results = [];
                        for (j = l = 0, ref1 = fields.length - 1; (0 <= ref1 ? l <= ref1 : l >= ref1); j = 0 <= ref1 ? ++l : --l) {
                          if (j === i) {
                            results.push(j + 1);
                          } else if (j === i + 1) {
                            results.push(j - 1);
                          } else {
                            results.push(j);
                          }
                        }
                        return results;
                      })());
                    })
                  }, f);
                });
                return child('a', {
                  href: '#',
                  onClick: ((e) => {
                    var newFields;
                    e.preventDefault();
                    e.stopPropagation();
                    if (this.props.editing) {
                      if (confirm(`Are you sure you want to delete the ${field.label || 'unnamed'} task? This cannot be undone.`)) {
                        return this.props.deleteField(field);
                      }
                    } else {
                      if (confirm(`Are you sure you want to delete the ${field.label || 'unnamed'} task? This cannot be undone.`)) {
                        newFields = fields.slice(0);
                        newFields.splice(i, 1);
                        this.props.onChange(update(this.props.game, {
                          fields: {
                            $set: newFields
                          }
                        }));
                        if (i < this.state.editingIndex) {
                          this.setState({
                            editingIndex: this.state.editingIndex - 1
                          });
                        } else if (i === this.state.editingIndex) {
                          this.setState({
                            editingIndex: null,
                            editingField: null
                          });
                        }
                      }
                    }
                  })
                }, () => {
                  return child('span.deleterow', () => {
                    raw('delete');
                  });
                });
              });
            });
          });
          if (this.state.showFieldTypes) {
            child('p', () => {
              return child('a.form-hide-types', {
                href: '#',
                onClick: ((e) => {
                  e.preventDefault();
                  this.setState({
                    showFieldTypes: false
                  });
                })
              }, () => {
                child('img.form-show-types-plus', {
                  src: '../assets/icons/field-x.png'
                });
                return child('span.form-show-types-label', () => {
                  raw('cancel');
                });
              });
            });
            return child('p', () => {
              var types;
              types = [
                ['TEXT', 'small text'],
                ['TEXTAREA', 'large text'],
                ['SINGLESELECT', 'single choice'],
                ['MULTISELECT', 'multiple choice'],
                ['MEDIA', 'photo'],
                // ['NUMBER', 'number'],
              ];
              return types.forEach(([type, name], i) => {
                return child('a.form-add-field', {
                  href: '#',
                  onClick: ((e) => {
                    e.preventDefault();
                    this.setState({
                      showFieldTypes: false
                    });
                    if (this.props.editing) {
                      return this.props.addField(type);
                    } else {
                      return this.props.onChange(update(this.props.game, {
                        fields: {
                          $set: fields.concat([
                            new Field({
                              field_type: type,
                              label: '',
                              required: false,
                              field_id: Date.now(), // temporary, to use as React key
                              options: (function() {
                                switch (type) {
                                  case 'SINGLESELECT':
                                  case 'MULTISELECT':
                                    return [
                                      {
                                        option: '',
                                        field_option_id: Date.now()
                                      }
                                    ];
                                  default:
                                    return undefined;
                                }
                              })()
                            })
                          ])
                        }
                      }));
                    }
                  })
                }, () => {
                  child('img', {
                    src: `../assets/icons/form-${type}.png`
                  });
                  child('br');
                  raw(name);
                });
              });
            });
          } else {
            return child('p', () => {
              return child('a.form-show-types', {
                href: '#',
                onClick: ((e) => {
                  e.preventDefault();
                  this.setState({
                    showFieldTypes: true
                  });
                })
              }, () => {
                child('img.form-show-types-plus', {
                  src: '../assets/icons/field-plus.png'
                });
                return child('span.form-show-types-label', () => {
                  raw('add new task');
                });
              });
            });
          }
        });
        return child('div.newStep4FieldInfo', () => {
          var confirmDelete, editingCategory, field, isLockedField, options, ref1, ref2, ref3, ref4, ref5, reloadThisField, req;
          if ((field = this.state.editingField) != null) {
            isLockedField = this.state.editingIndex < 0;
            reloadThisField = () => {
              var f, i, l, len, ref1;
              if (isLockedField) {
                if (field.field_type === 'SINGLESELECT') {
                  this.setState({
                    editingField: new Field({
                      field_type: 'SINGLESELECT',
                      label: 'Category',
                      required: true,
                      options: categoryOptions()
                    }),
                    deletingOption: null
                  });
                }
              } else {
                ref1 = this.props.fields;
                for (i = l = 0, len = ref1.length; l < len; i = ++l) {
                  f = ref1[i];
                  if (f.field_id === field.field_id) {
                    this.setState({
                      editingField: f,
                      editingIndex: i,
                      deletingOption: null
                    });
                    return;
                  }
                }
              }
            };
            if (this.state.deletingOption != null) {
              child('p', () => {
                raw('Before you delete this option, you must reassign posts that use it to an existing option.');
              });
              child('p', () => {
                raw(`Reassign posts with the '${this.state.deletingOption.option}' option to:`);
              });
              confirmDelete = (new_option) => {
                var msg;
                msg = new_option != null ? `Are you sure you want to delete the option '${this.state.deletingOption.option}' and reassign its notes to '${new_option.option}'?` : `Are you sure you want to delete the option '${this.state.deletingOption.option}'?`;
                if (confirm(msg)) {
                  if (isLockedField) {
                    return this.props.deleteCategory({
                      tag_id: this.state.deletingOption.field_option_id,
                      new_tag_id: new_option.field_option_id
                    }, reloadThisField);
                  } else {
                    return this.props.deleteFieldOption({
                      field_option: this.state.deletingOption,
                      new_field_option: new_option
                    }, reloadThisField);
                  }
                }
              };
              child('ul', () => {
                var ref1;
                return ((ref1 = field.options) != null ? ref1 : []).forEach((o) => {
                  if (o.field_option_id !== this.state.deletingOption.field_option_id) {
                    return child('li', {
                      key: o.field_option_id
                    }, () => {
                      return child('a', {
                        href: '#',
                        onClick: (e) => {
                          e.preventDefault();
                          return confirmDelete(o);
                        }
                      }, () => {
                        raw(o.option);
                      });
                    });
                  }
                });
              });
              if (!isLockedField) {
                child('p', () => {
                  return child('a', {
                    href: '#',
                    onClick: (e) => {
                      e.preventDefault();
                      return confirmDelete(null);
                    }
                  }, () => {
                    raw("Don't reassign");
                  });
                });
              }
              return child('p', () => {
                return child('a', {
                  href: '#',
                  onClick: (e) => {
                    e.preventDefault();
                    this.setState({
                      deletingOption: null
                    });
                  }
                }, () => {
                  raw("Cancel");
                });
              });
            } else {
              child('div.inspectortitle', () => {
                child('img.inspectoricon', {
                  src: `../assets/icons/form-${field.field_type}.png`
                });
                return child('h2', () => {
                  if (isLockedField) {
                    raw(field.label);
                  } else {
                    switch (field.field_type) {
                      case 'TEXT':
                        return raw('Small text');
                      case 'TEXTAREA':
                        return raw('Large text');
                      case 'MEDIA':
                        return raw('Image upload');
                      case 'SINGLESELECT':
                        return raw('Single choice');
                      case 'MULTISELECT':
                        return raw('Multiple choice');
                    }
                  }
                });
              });
              if (!isLockedField) {
                child('div.inspector-question', () => {
                  return child('input', {
                    type: 'text',
                    value: field.label,
                    placeholder: 'Label',
                    onChange: (e) => {
                      this.setState({
                        editingField: update(field, {
                          label: {
                            $set: e.target.value
                          }
                        })
                      });
                    }
                  });
                });
                child('div.inspector-question', () => {
                  return child('textarea', {
                    value: field.instruction,
                    placeholder: 'Task instructions',
                    onChange: (e) => {
                      this.setState({
                        editingField: update(field, {
                          instruction: {
                            $set: e.target.value
                          }
                        })
                      });
                    }
                  });
                });
                if (true) {
                  req = field.required;
                  child(`a.form-multi-option.form-multi-option-${(req ? 'on' : 'off')}`, {
                    href: '#'
                  }, () => {
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        this.setState({
                          editingField: update(field, {
                            required: {
                              $set: !req
                            },
                            useOnCards: (field.field_type === 'MEDIA' && req) ? {$set: false} : {},
                          })
                        });
                      }
                    });
                    child('span.form-multi-option-text', () => {
                      raw('Required');
                    });
                    return child('span.form-multi-option-switch', () => {
                      return child('span.form-multi-option-ball');
                    });
                  });
                }
                if (field.field_type === 'SINGLESELECT' || field.field_type === 'MULTISELECT') {
                  const selectMode = field.noFieldNote ? 'observation' :
                    field.noObservation ? 'field' :
                    'both';
                  child('div.form-multi-option', () => {
                    child('select.full-width-input', {value: selectMode}, () => {
                      props({onChange: e => {
                        this.setState({
                          editingField: update(field, {
                            noFieldNote: {
                              $set: e.target.value === 'observation',
                            },
                            noObservation: {
                              $set: e.target.value === 'field',
                            },
                          })
                        });
                      }});
                      child('option', {value: 'both'}, () => raw('Use as task and collect field notes'));
                      child('option', {value: 'observation'}, () => raw("Only use as observation task"));
                      child('option', {value: 'field'}, () => raw("Only collect as field notes"));
                    });
                  });
                }
              }
              if (field.field_type === 'TEXTAREA' && isLockedField) {
                if (this.props.editing) {
                  child('textarea.full-width-textarea', {
                    placeholder: 'Pre-filled caption text',
                    defaultValue: (ref2 = this.props.game.prompt) != null ? ref2 : '',
                    ref: 'caption'
                  });
                } else {
                  child('textarea.full-width-textarea', {
                    placeholder: 'Pre-filled caption text',
                    value: (ref3 = this.props.game.prompt) != null ? ref3 : '',
                    onChange: (e) => {
                      return this.props.onChange(update(this.props.game, {
                        prompt: {
                          $set: e.target.value
                        }
                      }));
                    }
                  });
                }
              }
              if (field.field_type === 'NUMBER') {
                child('ul', () => {
                  child(ColorNumberInput, {
                    label: 'Min',
                    game: this.props.game,
                    colors: this.props.colors,
                    value: field.min,
                    color: field.min_color,
                    onChangeValue: (v) => {
                      this.setState({
                        editingField: update(field, {min: {$set: v}}),
                      });
                    },
                    onChangeColor: (v) => {
                      this.setState({
                        editingField: update(field, {min_color: {$set: v}}),
                      });
                    },
                  });
                  child(ColorNumberInput, {
                    label: 'Max',
                    game: this.props.game,
                    colors: this.props.colors,
                    value: field.max,
                    color: field.max_color,
                    onChangeValue: (v) => {
                      this.setState({
                        editingField: update(field, {max: {$set: v}}),
                      });
                    },
                    onChangeColor: (v) => {
                      this.setState({
                        editingField: update(field, {max_color: {$set: v}}),
                      });
                    },
                  });
                  child('li.field-option-row', () => {
                    child(NumberInput, {
                      label: 'Step',
                      value: field.step,
                      onChangeValue: (v) => {
                        this.setState({
                          editingField: update(field, {step: {$set: v}}),
                        });
                      },
                    });
                  });
                });
              }
              if ((ref4 = field.field_type) === 'SINGLESELECT' || ref4 === 'MULTISELECT') {
                editingCategory = this.props.editing && isLockedField;
                options = (ref5 = field.options) != null ? ref5 : [];
                child('ul', () => {
                  options.forEach((o, i) => {
                    return child(CategoryRow, {
                      key: o.field_option_id,
                      o: o,
                      i: i,
                      game: this.props.game,
                      colors: this.props.colors,
                      options: options,
                      isLockedField: isLockedField,
                      editing: this.props.editing,
                      editingCategory: editingCategory,
                      reorderFieldOptions: (indexes) => {
                        return this.reorderFieldOptions(indexes, reloadThisField);
                      },
                      startDeletingOption: (o) => {
                        this.setState({
                          deletingOption: o
                        });
                      },
                      updateOptions: (opts) => {
                        this.setState({
                          editingField: update(field, {
                            options: {
                              $set: opts
                            }
                          })
                        });
                      },
                      updateCategory: (obj) => {
                        return this.props.updateCategory(obj, reloadThisField);
                      },
                      updateFieldOption: (obj) => {
                        return this.props.updateFieldOption(obj, reloadThisField);
                      }
                    });
                  });
                  return child('li', () => {
                    return child('a', {
                      onClick: (() => {
                        if (this.props.editing) {
                          if (editingCategory) {
                            return this.props.addCategory({
                              name: ''
                            }, reloadThisField);
                          } else {
                            return this.props.addFieldOption({
                              field: field,
                              option: ''
                            }, reloadThisField);
                          }
                        } else {
                          this.setState({
                            editingField: update(field, {
                              options: {
                                $set: options.concat([
                                  {
                                    option: '',
                                    field_option_id: Date.now()
                                  }
                                ])
                              }
                            })
                          });
                        }
                      })
                    }, () => {
                      return child('span.addoption_btn', () => {
                        child('img.addoption', {
                          src: '../assets/icons/addfield.png'
                        });
                        raw('add answer');
                      });
                    });
                  });
                });
              }
              return child('p.savebutton', () => {
                return child('span.button', {
                  onClick: () => {
                    if (isLockedField) {
                      switch (field.field_type) {
                        case 'TEXTAREA':
                          if (this.props.editing) {
                            this.props.setPrompt(this.refs.caption.value);
                          }
                          break;
                        case 'SINGLESELECT':
                          if (!this.props.editing) {
                            this.props.onChangeCategories(field.options.map((o) => {
                              return {
                                category: o.option,
                                color: o.color
                              };
                            }));
                          }
                      }
                    } else if (this.props.editing) {
                      this.props.updateField(field);
                    } else {
                      this.props.onChange(update(this.props.game, {
                        fields: {
                          $apply: (fields) => (
                            fields.map((someField, i) => {
                              if (i === this.state.editingIndex) {
                                return field;
                              }
                              if (field.useAsPin && someField.useAsPin) {
                                return update(someField, {useAsPin: {$set: false}});
                              }
                              if (field.useOnCards && someField.useOnCards) {
                                const thisIsPhoto = field.field_type === 'MEDIA';
                                const thatIsPhoto = someField.field_type === 'MEDIA';
                                if (thisIsPhoto === thatIsPhoto) {
                                  return update(someField, {useOnCards: {$set: false}});
                                }
                              }
                              return someField;
                            })
                          ),
                        },
                      }));
                    }
                    this.setState({
                      editingField: null,
                      editingIndex: null
                    });
                  }
                }, () => {
                  raw('Save task');
                });
              });
            }
          } else {
            return child('p', () => {
              raw('No task selected.');
            });
          }
        });
      });
      if (this.props.editing) {
        return child('div.bottom-step-buttons', () => {
          child('a', {
            href: '#map' + this.props.game.game_id
          }, () => {
            return child('div.newPrevButton', () => {
              raw('< map');
            });
          });
          return child('div');
        });
      } else {
        return child('div.bottom-step-buttons', () => {
          child('a', {
            href: '#quest2'
          }, () => {
            return child('div.newPrevButton', () => {
              raw('< onboarding');
            });
          });
          return child('a', {
            href: '#quest4'
          }, () => {
            return child('div.newNextButton', () => {
              raw('field notes >');
            });
          });
        });
      }
    });
  }
});

const FieldNotes = createClass({
  displayName: 'FieldNotes',
  getInitialState: function() {
    return {};
  },
  render: function() {

    const fieldNoteGroups = this.props.game.fields.filter(field =>
      (field.field_type === 'SINGLESELECT' || field.field_type === 'MULTISELECT')
      && !(field.noFieldNote)
    );
    let selectedGroup = null;
    let selectedOption = null;
    if (this.state.selectedOptionID != null) {
      fieldNoteGroups.forEach(group => {
        group.options.forEach(option => {
          if (this.state.selectedOptionID === option.field_option_id) {
            selectedGroup = group;
            selectedOption = option;
          }
        });
      });
    } else if (this.state.selectedGroupID != null) {
      fieldNoteGroups.forEach(group => {
        if (this.state.selectedGroupID === group.field_id) {
          selectedGroup = group;
        }
      });
    }

    const updateSelectedGroup = (o) => {
      this.props.onChange(update(this.props.game, {
        fields: (fields) => fields.map(field => {
          if (field.field_id === selectedGroup.field_id) {
            return update(field, o);
          } else {
            return field;
          }
        }),
      }));
    };

    const updateSelectedOption = (o) => {
      this.props.onChange(update(this.props.game, {
        fields: (fields) => fields.map(field => {
          if (field.field_id === selectedGroup.field_id) {
            return update(field, {
              options: (options) => options.map(option => {
                if (option.field_option_id === selectedOption.field_option_id) {
                  return update(option, o);
                } else {
                  return option;
                }
              }),
            });
          } else {
            return field;
          }
        }),
      }));
    };

    return (
      <div className="newStepBox">
        <div className="newStep1">
          <div className="newStep1Column newStep1LeftColumn field-notes-groups">
            {
              fieldNoteGroups.map(group =>
                <div className="field-notes-group" key={group.field_id}>
                  <a href="#" className={
                    this.state.selectedGroupID === group.field_id
                    ? "field-notes-header selected"
                    : "field-notes-header"
                  } onClick={e => {
                    e.preventDefault();
                    this.setState({selectedGroupID: group.field_id, selectedOptionID: null});
                  }}>
                    <h1>{group.label}</h1>
                  </a>
                  {
                    group.options.map(opt =>
                      <a href="#" key={opt.field_option_id} className={
                        this.state.selectedOptionID === opt.field_option_id
                        ? "field-notes-item selected"
                        : "field-notes-item"
                      } onClick={(e) => {
                        e.preventDefault();
                        this.setState({selectedOptionID: opt.field_option_id, selectedGroupID: null});
                      }}>
                        <h2>{opt.option}</h2>
                        <p>
                          {(() => {
                            const plaque = (this.props.game.plaques || []).find(plaque =>
                              (plaque.fieldNotes || []).indexOf(opt.field_option_id) !== -1
                            );
                            if (plaque) {
                              return <span>Attached to: {plaque.name}</span>;
                            } else {
                              return <span>Spawns Randomly</span>;
                            }
                          })()}
                        </p>
                      </a>
                    )
                  }
                </div>
              )
            }
          </div>
          <div className="newStep1Column newStep1RightColumn">
            {
              selectedOption && (
                <div>
                  <h2>Field Note</h2>
                  <label>
                    Field Note Title:
                    <input
                      type="text"
                      placeholder="Title"
                      value={selectedOption.option}
                      onChange={e => updateSelectedOption({option: {$set: e.target.value}})}
                    />
                  </label>
                  <label>
                    Field Note Summary:
                    <textarea
                      placeholder="Description"
                      value={selectedOption.description || ''}
                      onChange={e => updateSelectedOption({description: {$set: e.target.value}})}
                    />
                  </label>
                  <MediaSelect
                    media={selectedOption.media}
                    media_id={selectedOption.media_id}
                    uploadMedia={this.props.uploadMedia}
                    game={this.props.game}
                    aris={this.props.aris}
                    applyMedia={(media) => {
                      updateSelectedOption({
                        media: {
                          $set: media, // includes url for displaying
                        },
                        media_id: {
                          $set: media.media_id, // to actually set in database
                        },
                      });
                    }}
                  />
                </div>
              )
            }
            {
              selectedGroup && !selectedOption && (
                <div>
                  <h2>Field Note Group</h2>
                  <label>
                    Field Note Group Title:
                    <input
                      type="text"
                      placeholder="Title"
                      value={selectedGroup.label}
                      onChange={e => updateSelectedGroup({label: {$set: e.target.value}})}
                    />
                  </label>
                  <label>
                    Field Note Group Prompt:
                    <textarea
                      placeholder="Description"
                      value={selectedGroup.prompt || ''}
                      onChange={e => updateSelectedGroup({prompt: {$set: e.target.value}})}
                    />
                  </label>
                </div>
              )
            }
          </div>
        </div>
        <div className="bottom-step-buttons">
          <a href="#quest3">
            <div className="newPrevButton">
              {'< observation'}
            </div>
          </a>
          <a href="#quest5">
            <div className="newNextButton">
              {'tour stops >'}
            </div>
          </a>
        </div>
      </div>
    );
  }
});

document.addEventListener('DOMContentLoaded', function(event) {
  return ReactDOM.render(make(App, {
    aris: new Aris
  }), document.getElementById('the-container'));
});
