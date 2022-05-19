'use strict';

import React from 'react';
import update from 'immutability-helper';
import {make, child, raw, props} from '../../shared/react-writer';
import createClass from "create-react-class";

import {SIFTR_URL} from '../../shared/aris';

import {SiftrIcon} from './siftr-icon';

function countContributors(notes) {
  var comment, l, len, len1, m, note, ref1, user_ids;
  user_ids = {};
  for (l = 0, len = notes.length; l < len; l++) {
    note = notes[l];
    user_ids[note.user.user_id] = true;
    ref1 = note.comments;
    for (m = 0, len1 = ref1.length; m < len1; m++) {
      comment = ref1[m];
      user_ids[comment.user.user_id] = true;
    }
  }
  return Object.keys(user_ids).length;
}

export const SiftrList = createClass({
  displayName: 'SiftrList',
  render: function() {
    return make('div.siftrList', () => {
      this.props.games.forEach((game) => {
        const notes = this.props.notes[game.game_id];
        child('div.siftr-entry', {
          key: `game-${game.game_id}`
        }, () => {
          child(SiftrIcon, {
            game: game,
            aris: this.props.aris,
            updateStateGame: this.props.updateStateGame
          });
          child('div.siftr-entry-right', () => {
            var colors, i, percent, points, rgb, tag, tags;
            child('div.siftr-entry-title-buttons', () => {
              child('div.siftr-entry-title', () => {
                raw(game.name);
              });
              child('span', () => {
                child('a', {
                  href: `\#edit${game.game_id}`
                }, () => {
                  return child('span.siftr-command-button', () => {
                    raw('EDIT');
                  });
                });
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      if (confirm(`Are you sure you want to delete "${game.name}"?`)) {
                        return this.props.onDelete(game);
                      }
                    }
                  });
                  child('span.siftr-command-button', () => {
                    raw('DELETE');
                  });
                });
                /*
                child('a', {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      this.props.downloadCSV(game);
                    }
                  });
                  child('span.siftr-command-button', () => {
                    raw('DOWNLOAD (.CSV)');
                  });
                });
                */
              });
            });
            child('div.siftr-data', () => {
              (this.props.quests[game.game_id] || []).forEach(quest => {
                child('div.quest-line', () => {
                  raw('Quest: ');
                  raw(quest.name);
                  raw(' ');
                  child('a', {href: '#'}, () => {
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        this.props.editOrCopyQuest(game, quest, false);
                      },
                    });
                    raw('(edit)');
                  })
                  raw(' ');
                  child('a', {href: '#'}, () => {
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        this.props.editOrCopyQuest(game, quest, true);
                      },
                    });
                    raw('(copy)');
                  })
                  raw(' ');
                  child('a', {href: '#'}, () => {
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        this.props.deleteQuest(quest);
                      },
                    });
                    raw('(delete)');
                  })
                });
              });
              child('div.quest-line', () => {
                child('a', {href: '#'}, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      this.props.startNewQuest(game);
                    }
                  });
                  raw('New Quest');
                });
              });
            });
          });
        });
      });
    });
  }
});
