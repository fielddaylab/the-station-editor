'use strict';

import React from 'react';
import ReactDOM from 'react-dom';
import update from 'immutability-helper';
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

export const ProfileSettings = createClass({
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

    return (
      <div className="settings">
        <p className="para-account-picture">
          <span
            className="big-account-picture"
            style={{
              backgroundImage:
                  this.state.new_icon    != null ? `url(${arisHTTPS(this.state.new_icon)})`
                : this.props.userPicture != null ? `url(${arisHTTPS(this.props.userPicture.url)})`
                : undefined
            }}
            onClick={this.selectUserPicture}
            onDragOver={(e) => {
              e.stopPropagation();
              e.preventDefault();
            }}
            onDrop={(e) => {
              var file, l, len, ref1;
              e.stopPropagation();
              e.preventDefault();
              ref1 = e.dataTransfer.files;
              for (l = 0, len = ref1.length; l < len; l++) {
                file = ref1[l];
                this.loadUserPicture(file);
                break;
              }
            }}
          />
        </p>
        <h4>Display name</h4>
        <p>
          <input
            className="full-width-input"
            autoCapitalize="off"
            autoCorrect="off"
            type="text"
            value={this.state.display_name || ''}
            onChange={(e) => {
              this.setState({
                display_name: e.target.value
              });
            }}
          />
        </p>
        <h4>Bio</h4>
        <p>
          <input
            className="full-width-input"
            type="text"
            value={this.state.bio || ''}
            onChange={(e) => {
              this.setState({
                bio: e.target.value
              });
            }}
          />
        </p>
        <h4>Website url</h4>
        <p>
          <input
            className="full-width-input"
            autoCapitalize="off"
            autoCorrect="off"
            type="text"
            value={this.state.url || ''}
            onChange={(e) => {
              this.setState({
                url: e.target.value
              });
            }}
          />
        </p>
        <p>
          <a href="#" className="settings-save" onClick={(e) => {
            e.preventDefault();
            return this.props.onSave({
              display_name: this.state.display_name,
              email: this.state.email,
              new_icon: this.state.new_icon,
              bio: this.state.bio,
              url: this.state.url
            });
          }}>
            Save
          </a>
        </p>
      </div>
    );
  }
});
