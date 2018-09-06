'use strict';

import React from 'react';
import createClass from "create-react-class";

import {
  Game,
  Colors,
  Theme,
  User,
  Tag,
  Comment,
  Note,
  Aris,
} from '../../shared/aris';

export const AccountSettings = createClass({
  displayName: 'AccountSettings',
  getInitialState: function() {
    return {
      email: this.props.auth.email,
      old_password: '',
      password: '',
      password2: ''
    };
  },
  render: function() {
    var ref1;
    const passwordBox = (placeholder, key) => (
      <p>
        <input
          className="full-width-input"
          type="password"
          autoCapitalize="off"
          autoCorrect="off"
          placeholder={placeholder}
          value={(ref1 = this.state[key]) != null ? ref1 : ''}
          onChange={(e) => {
            this.setState({[key]: e.target.value});
          }}
        />
      </p>
    );
    return (
      <div className="settings">
        <h4>Email</h4>
        <p>
          <input
            className="full-width-input"
            type="text"
            autoCapitalize="off"
            autoCorrect="off"
            value={(ref1 = this.state.email) != null ? ref1 : ''}
            onChange={(e) => {
              this.setState({email: e.target.value});
            }}
          />
        </p>
        <h3>Change Password</h3>
        {passwordBox('old password', 'old_password')}
        {passwordBox('new password', 'password')}
        {passwordBox('repeat password', 'password2')}
        <p>
          <a href="#" className="settings-save" onClick={(e) => {
            e.preventDefault();
            const save = () => {
              return this.props.onSave({
                email: this.state.email,
                user_name: this.props.aris.auth.username,
                old_password: this.state.old_password,
                new_password: this.state.password
              });
            };
            if (this.state.password === '' && this.state.password2 === '') {
              save();
            } else if (!this.state.old_password) {
              alert('Please enter your current password.');
            } else if (!(this.state.password || this.state.password2)) {
              alert('Please enter a new password.');
            } else if (this.state.password !== this.state.password2) {
              alert('Your two passwords do not match.');
            } else {
              save();
            }
          }}>
            Save
          </a>
        </p>
      </div>
    );
  }
});
