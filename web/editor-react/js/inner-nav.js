'use strict';

import React from 'react';
import update from 'immutability-helper';

import {
  arisHTTPS,
} from '../../shared/aris';

export const InnerNav = (props) => {
  function navTab({href, label, screen}) {
    const className =
      screen === props.screen ?
      'inner-nav-bar-item inner-nav-bar-item-current' :
      'inner-nav-bar-item';
    return <a className={className} href={href}>{ label }</a>;
  }
  return (
    <div className="inner-nav">
      <div className="inner-nav-user">
        <div className="inner-nav-pic" style={{
          backgroundImage: props.userPicture != null ? `url(${arisHTTPS(props.userPicture.thumb_url)})` : undefined
        }} />
        <div className="inner-nav-headers">
          <h1 className="inner-nav-name">
            {props.auth.display_name}
            <a href="#" className="inner-nav-button" onClick={(e) => {
              e.preventDefault();
              props.logout();
            }}>
              Log Out
            </a>
            <a href="#new0" className="inner-nav-button">
              New Siftr
            </a>
          </h1>
          {
            props.auth.bio
            ? <p className="inner-nav-bio">{props.auth.bio}</p>
            : undefined
          }
          {
            props.auth.url
            ? <p className="inner-nav-url">
                <a href={props.auth.url} target="_blank">
                  {props.auth.url}
                </a>
              </p>
            : undefined
          }
        </div>
      </div>
      <div className="inner-nav-bar">
        {navTab({href: '#profile', label: 'Profile', screen: 'profile'})}
        {navTab({href: '#account', label: 'Account', screen: 'account'})}
        {navTab({href: '#', label: 'My Siftrs', screen: 'main'})}
        <a className="inner-nav-bar-filler" />
      </div>
    </div>
  );
};
