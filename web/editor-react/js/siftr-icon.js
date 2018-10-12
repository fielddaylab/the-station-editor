'use strict';

import React from 'react';
import update from 'immutability-helper';
import createClass from "create-react-class";

import {
  Game,
  Colors,
  Theme,
  User,
  Tag,
  Note,
  arisHTTPS,
} from '../../shared/aris';

export const SiftrIcon = createClass({
  displayName: 'SiftrIcon',
  getInitialState: function() {
    return {
      url: null
    };
  },
  fetchIcon: function(props) {
    var media_id;
    media_id = parseInt(props.game.icon_media_id);
    if (!media_id) {
      return;
    }
    if (media_id === this.fetchedMediaID) {
      return;
    }
    this.fetchedMediaID = media_id;
    return props.aris.call('media.getMedia', {
      media_id: media_id
    }, (result) => {
      if (result.returnCode === 0 && (result.data != null)) {
        this.setState({
          url: result.data.thumb_url
        });
      }
    });
  },
  componentDidMount: function() {
    return this.fetchIcon(this.props);
  },
  componentWillReceiveProps: function(nextProps, nextState) {
    return this.fetchIcon(nextProps);
  },
  loadImageFile: function(file) {
    var fr;
    fr = new FileReader;
    fr.onload = () => {
      var base64, dataURL, ext, extmap;
      dataURL = fr.result;
      if (dataURL == null) {
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
        return this.props.aris.call('media.createMedia', {
          game_id: this.props.game.game_id,
          file_name: `upload.${ext}`,
          data: base64
        }, (result) => {
          if (result != null) {
            return this.props.aris.call('games.updateGame', {
              game_id: this.props.game.game_id,
              icon_media_id: result.data.media_id
            }, ({
                data: game
              }) => {
              return this.props.updateStateGame(new Game(game));
            });
          }
        });
      }
    };
    return fr.readAsDataURL(file);
  },
  render: function() {
    return <a
      className="siftr-icon"
      href="#"
      onClick={(e) => {
        var input;
        e.preventDefault();
        input = document.createElement('input');
        input.type = 'file';
        input.onchange = (e) => {
          return this.loadImageFile(e.target.files[0]);
        };
        return input.click();
      }}
      style={this.state.url == null ? {} : {
        backgroundImage: `url(${arisHTTPS(this.state.url)})`,
      }}
    />;
  }
});
