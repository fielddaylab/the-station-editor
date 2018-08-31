'use strict';

import React from 'react';
import ReactDOM from 'react-dom';
import update from 'react-addons-update';
import {make, child, raw, props} from '../../shared/react-writer';

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

export const ProfileSettings = React.createClass({
  displayName: 'ProfileSettings',
  getInitialState: function() {
    return {
      display_name: this.props.auth.display_name,
      new_icon: null,
      bio: this.props.auth.bio,
      url: this.props.auth.url
    };
  },
  selectUserPicture: function() {
    var input;
    input = document.createElement('input');
    input.type = 'file';
    input.onchange = (e) => {
      return this.loadUserPicture(e.target.files[0]);
    };
    return input.click();
  },
  loadUserPicture: function(file) {
    var fr;
    fr = new FileReader;
    fr.onload = () => {
      this.setState({
        new_icon: fr.result
      });
    };
    return fr.readAsDataURL(file);
  },
  render: function() {
    return make('div.settings', () => {
      child('p.para-account-picture', () => {
        child('span.big-account-picture', {
          style: {
            backgroundImage: this.state.new_icon != null ? `url(${this.state.new_icon})` : this.props.userPicture != null ? `url(${this.props.userPicture.url})` : undefined
          },
          onClick: this.selectUserPicture,
          onDragOver: (e) => {
            e.stopPropagation();
            e.preventDefault();
          },
          onDrop: (e) => {
            var file, l, len, ref1;
            e.stopPropagation();
            e.preventDefault();
            ref1 = e.dataTransfer.files;
            for (l = 0, len = ref1.length; l < len; l++) {
              file = ref1[l];
              this.loadUserPicture(file);
              break;
            }
          }
        });
      });
      child('h4', () => {
        raw('Display name');
      });
      child('p', () => {
        var ref1;
        child('input.full-width-input', {
          autoCapitalize: 'off',
          autoCorrect: 'off',
          type: 'text',
          value: (ref1 = this.state.display_name) != null ? ref1 : '',
          onChange: (e) => {
            this.setState({
              display_name: e.target.value
            });
          }
        });
      });
      child('h4', () => {
        raw('Bio');
      });
      child('p', () => {
        var ref1;
        return child('input.full-width-input', {
          type: 'text',
          value: (ref1 = this.state.bio) != null ? ref1 : '',
          onChange: (e) => {
            this.setState({
              bio: e.target.value
            });
          }
        });
      });
      child('h4', () => {
        raw('Website url');
      });
      child('p', () => {
        var ref1;
        child('input.full-width-input', {
          autoCapitalize: 'off',
          autoCorrect: 'off',
          type: 'text',
          value: (ref1 = this.state.url) != null ? ref1 : '',
          onChange: (e) => {
            this.setState({
              url: e.target.value
            });
          }
        });
      });
      child('p', () => {
        child('a.settings-save', {
          href: '#'
        }, () => {
          props({
            onClick: (e) => {
              e.preventDefault();
              return this.props.onSave({
                display_name: this.state.display_name,
                email: this.state.email,
                new_icon: this.state.new_icon,
                bio: this.state.bio,
                url: this.state.url
              });
            }
          });
          raw('Save');
        });
      });
    });
  }
});
