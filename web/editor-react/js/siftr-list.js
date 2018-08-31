'use strict';

import React from 'react';
import update from 'react-addons-update';
import {make, child, raw, props} from '../../shared/react-writer';

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

export const SiftrList = React.createClass({
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
              child('a.siftr-entry-title', {
                href: `${SIFTR_URL}${game.siftr_url || game.game_id}`,
                target: '_blank'
              }, () => {
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
              });
            });
            child('div.siftr-color-bar', {
              style: {
                backgroundImage: (function() {
                  var l, len;
                  if (((colors = this.props.colors[game.colors_id]) != null) && ((tags = this.props.tags[game.game_id]) != null)) {
                    percent = 0;
                    points = [];
                    for (i = l = 0, len = tags.length; l < len; i = ++l) {
                      tag = tags[i];
                      rgb = tag.color || colors[`tag_${(i % 8) + 1}`];
                      points.push(`${rgb} ${percent}%`);
                      percent += 100 / tags.length;
                      points.push(`${rgb} ${percent}%`);
                    }
                    return `linear-gradient(to right, ${points.join(', ')})`;
                  } else {
                    return 'linear-gradient(to right, gray, gray)';
                  }
                }).call(this)
              }
            });
            child('div.siftr-data', () => {
              var plural, sep;
              sep = () => {
                child('span.siftr-data-pipe', () => {
                  raw('|');
                });
              };
              plural = function(n, noun) {
                if (n === 1) {
                  return `${n} ${noun}`;
                } else {
                  return `${n != null ? n : '...'} ${noun}s`;
                }
              };
              raw(plural(notes != null ? notes.length : undefined, 'item'));
              sep();
              raw(plural((notes != null ? countContributors(notes) : null), 'contributor'));
              sep();
              raw((game.published ? 'Public' : 'Private'));
              sep();
              raw((game.moderated ? 'Moderated' : 'Non-Moderated'));
            });
          });
        });
      });
    });
  }
});
