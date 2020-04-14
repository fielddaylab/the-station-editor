'use strict';

import React from 'react';
import update from 'immutability-helper';

export const MediaSelect = (props) => {
  return (
    <a href="#" onClick={e => {
      e.preventDefault();
      props.pickAndUploadMedia(props.game, props.applyMedia);
    }}>
      {
        props.media ? (
          <p>
            <img
              src={props.media.big_thumb_url}
              style={{
                width: '100%',
                maxWidth: 300,
              }}
            />
          </p>
        ) : (
          <p>
            Select media
          </p>
        )
      }
    </a>
  );
};
