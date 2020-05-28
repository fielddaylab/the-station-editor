'use strict';

import React from 'react';
import update from 'immutability-helper';
import createClass from "create-react-class";
import Croppie from 'croppie/croppie';

const CropModal = createClass({
  displayName: 'CropModal',
  getInitialState: function(){
    return {};
  },
  componentDidMount: function(){
    this.crop = new Croppie(this.cropDiv, {
      //enableExif: true,
      viewport: {width: 200, height: 200, type: 'square'},
      showZoomer: false,
    });
    this.crop.bind({
      url: this.props.url,
      zoom: 0, // set to lowest possible
    });
  },
  componentWillUnmount: function(){
    this.crop.destroy();
  },
  render: function(){
    return (
      <div onMouseDown={(e) => {
        this.props.onCancel();
      }} style={{
        position: 'fixed',
        zIndex: 999,
        top: 0, left: 0, bottom: 0, right: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
        <div onMouseDown={(e) => e.stopPropagation()} style={{
          backgroundColor: 'white',
          padding: 15,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'stretch',
        }}>
          <p>Adjust crop area</p>
          <hr style={{width: '100%'}} />
          <div ref={(r) => (this.cropDiv = r)} style={{
            width: 450,
            height: 300,
            alignSelf: 'center',
            margin: 10,
          }} />
          <a href="#" onClick={(e) => {
            e.preventDefault();
            if (!this.crop) return;
            const points = this.crop.get().points;
            // points are [x1, y1, x2, y2] into original image
            const width = parseInt(points[2]) - parseInt(points[0]);
            const maxSize = 800;
            this.crop.result({
              type: 'blob',
              size: width > maxSize ? {width: maxSize} : 'original',
            }).then(this.props.onCrop)
          }} style={{
            margin: 10,
            backgroundColor: 'rgb(100,94,242)',
            color: 'white',
            padding: 10,
            alignSelf: 'center',
            borderRadius: 5,
          }}>
            Crop and Save
          </a>
        </div>
      </div>
    );
  },
});

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

    if (this.state.croppingURL) {
      return (
        <CropModal
          url={this.state.croppingURL}
          onCancel={() => this.setState({croppingURL: null})}
          onCrop={(file) => {
            this.props.uploadMedia(file, this.props.applyMedia);
            this.setState({croppingURL: null});
          }}
        />
      );
    }

    return (
      <a href="#"
        onClick={e => {
          e.preventDefault();
          let input = document.createElement('input');
          input.type = 'file';
          input.onchange = (e) => {
            const file = e.target.files[0];
            if (true) { // was gated for debugging
              let fr = new FileReader;
              fr.onload = () => {
                const dataURL = fr.result;
                this.setState({croppingURL: dataURL});
              };
              fr.readAsDataURL(file);
            } else {
              this.props.uploadMedia(file, this.props.applyMedia);
            }
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
            // let fr = new FileReader;
            // fr.onload = () => {
            //   const dataURL = fr.result;
            //   this.setState({croppingURL: dataURL});
            // };
            // fr.readAsDataURL(files[0]);
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
