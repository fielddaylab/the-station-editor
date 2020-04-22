'use strict';

import React from 'react';
import update from 'immutability-helper';
import createClass from "create-react-class";

export const MediaSelect = createClass({
  displayName: 'MediaSelect',
  getInitialState: function(){
    return {
      loadedFromID: null,
    };
  },
  componentDidMount: function(){
    this.loadIfNeeded();
  },
  componentDidUpdate: function(){
    this.loadIfNeeded();
  },
  loadIfNeeded: function(){
    if (this.props.media_id && !this.props.media && !this.getLoadedMedia()) {
      this.props.aris.call('media.getMedia', {
        media_id: this.props.media_id
      }, (result) => {
        if (result.returnCode === 0 && (result.data != null)) {
          this.setState({
            loadedFromID: result.data
          });
        }
      });
    }
  },
  getLoadedMedia: function(){
    if (this.state.loadedFromID) {
      if (parseInt(this.state.loadedFromID.media_id) === parseInt(this.props.media_id)) {
        return this.state.loadedFromID;
      }
    }
    return null;
  },
  render: function(){
    const mediaObject = this.props.media || this.getLoadedMedia();
    return (
      <a href="#"
        onClick={e => {
          e.preventDefault();
          let input = document.createElement('input');
          input.type = 'file';
          input.onchange = (e) => {
            const file = e.target.files[0];
            this.props.uploadMedia(file, this.props.applyMedia);
          };
          input.click();
        }}
        onDragOver={e => {
          e.stopPropagation();
          e.preventDefault();
        }}
        onDrop={e => {
          e.stopPropagation();
          e.preventDefault();
          const files = e.dataTransfer.files;
          if (files.length > 0) {
            this.props.uploadMedia(files[0], this.props.applyMedia);
          }
        }}
      >
        {
          mediaObject ? (
            <div className="media-some" style={{
              backgroundImage: `url(${mediaObject.big_thumb_url})`,
            }} />
          ) : (
            <div className="media-none">
              <p>
                <img src="img/icon-image.png" style={{
                  width: 274 / 4,
                  height: 276 / 4,
                }} />
              </p>
              <p>
                Drag and Drop Image
              </p>
            </div>
          )
        }
      </a>
    );
  },
});
