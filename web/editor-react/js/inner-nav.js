'use strict';

import React from 'react';
import update from 'react-addons-update';
import {make, child, raw, props} from '../../shared/react-writer';

import {
  arisHTTPS,
} from '../../shared/aris';

export const InnerNav = (thisProps) => (
  make('div.inner-nav', () => {
    child('div.inner-nav-user', () => {
      child('div.inner-nav-pic', {
        style: {
          backgroundImage: thisProps.userPicture != null ? `url(${arisHTTPS(thisProps.userPicture.thumb_url)})` : undefined
        }
      });
      return child('div.inner-nav-headers', () => {
        child('h1.inner-nav-name', () => {
          raw(thisProps.auth.display_name);
          return child('a.inner-nav-logout', {
            href: '#'
          }, () => {
            props({
              onClick: (e) => {
                e.preventDefault();
                return thisProps.logout();
              }
            });
            raw('Log Out');
          });
        });
        if (thisProps.auth.bio) {
          child('p.inner-nav-bio', () => {
            raw(thisProps.auth.bio);
          });
        }
        if (thisProps.auth.url) {
          return child('p.inner-nav-url', () => {
            return child('a', {
              href: thisProps.auth.url,
              target: '_blank'
            }, () => {
              raw(thisProps.auth.url);
            });
          });
        }
      });
    });
    return child('div.inner-nav-bar', () => {
      var className, href, l, label, len, navs, screen;
      navs = [
        {
          href: '#profile',
          label: 'Profile',
          screen: 'profile'
        },
        {
          href: '#account',
          label: 'Account',
          screen: 'account'
        },
        {
          href: '#',
          label: 'My Siftrs',
          screen: 'main'
        }
      ];
      for (l = 0, len = navs.length; l < len; l++) {
        ({href, label, screen} = navs[l]);
        className = screen === thisProps.screen ? 'a.inner-nav-bar-item.inner-nav-bar-item-current' : 'a.inner-nav-bar-item';
        child(className, {
          href: href
        }, () => {
          raw(label);
        });
      }
      return child('a.inner-nav-bar-filler');
    });
  })
);
