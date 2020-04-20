'use strict';

import React from 'react';
import update from 'immutability-helper';

export const MediaSelect = (props) => {
  return (
    <a href="#"
      onClick={e => {
        e.preventDefault();
        let input = document.createElement('input');
        input.type = 'file';
        input.onchange = (e) => {
          const file = e.target.files[0];
          props.uploadMedia(file, props.applyMedia);
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
          props.uploadMedia(files[0], props.applyMedia);
        }
      }}
    >
      {
        props.media ? (
          <div className="media-some" style={{
            backgroundImage: `url(${props.media.big_thumb_url})`,
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
};
