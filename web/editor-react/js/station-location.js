'use strict';

import React from 'react';
import update from 'immutability-helper';
import {make, child, raw, props} from '../../shared/react-writer';
import createClass from "create-react-class";

import GoogleMap from 'google-map-react';

import {
  Game,
  Colors,
  Theme,
  User,
  Aris,
} from '../../shared/aris';

import {MediaSelect} from './media-select';

export const StationLocation = createClass({
  displayName: 'StationLocation',

  getInitialState: function() {
    return {
      draggingPin: false,
    };
  },

  getMapStyles: function(props = this.props) {
    var styles, theme;
    styles = [];
    styles.push({
      featureType: 'transit',
      stylers: [
        {
          visibility: 'off'
        }
      ]
    });
    styles.push({
      featureType: 'poi',
      stylers: [
        {
          visibility: 'off'
        }
      ]
    });
    if (!props.game.map_show_roads) {
      styles.push({
        featureType: 'road',
        stylers: [
          {
            visibility: 'off'
          }
        ]
      });
    }
    if (!props.game.map_show_labels) {
      styles.push({
        elementType: 'labels',
        stylers: [
          {
            visibility: 'off'
          }
        ]
      });
      styles.push({
        featureType: 'administrative.land_parcel',
        stylers: [
          {
            visibility: 'off'
          }
        ]
      });
      styles.push({
        featureType: 'administrative.neighborhood',
        stylers: [
          {
            visibility: 'off'
          }
        ]
      });
    }
    return styles;
  },

  render: function() {
    return (
      <div className="newStepBox">
        <div className="newStep3">
          <div className="newStep3Controls">
            <div className="tour-stop-edit">
              <label>
                Science Station Coordinates:
                <input
                  type="text"
                  placeholder="Latitude"
                  value={this.props.game.latitude}
                  onChange={e => this.props.onChange(update(this.props.game, {
                    latitude: {
                      $set: e.target.value,
                    },
                  }))}
                />
                <input
                  type="text"
                  placeholder="Longitude"
                  value={this.props.game.longitude}
                  onChange={e => this.props.onChange(update(this.props.game, {
                    longitude: {
                      $set: e.target.value,
                    },
                  }))}
                />
              </label>
            </div>
          </div>
          <div className="newStep3MapContainer">
            <GoogleMap
              bootstrapURLKeys={{
                key: 'AIzaSyDlMWLh8Ho805A5LxA_8FgPOmnHI0AL9vw',
              }}
              defaultCenter={[this.props.game.latitude, this.props.game.longitude]}
              defaultZoom={Math.max(2, this.props.game.zoom)}
              options={(maps) => {
                return {
                  minZoom: 2,
                  styles: this.getMapStyles(),
                  mapTypeId: maps.MapTypeId.HYBRID,
                  fullscreenControl: false,
                };
              }}
              draggable={!this.state.draggingPin}
              onChildMouseDown={(childKey, childProps, mouse) => {
                this.setState({draggingPin: true});
              }}
              onChildMouseMove={(childKey, childProps, mouse) => {
                this.props.onChange(update(this.props.game, {
                  latitude: {$set: mouse.lat},
                  longitude: {$set: mouse.lng},
                }));
              }}
              onChildMouseUp={(childKey, childProps, mouse) => {
                this.setState({draggingPin: false});
              }}
            >
              <div
                className="color-card-pin"
                lat={this.props.game.latitude}
                lng={this.props.game.longitude}
              >
                <div className="siftr-map-note">
                  <div className="siftr-map-note-shadow" />
                  <div className="siftr-map-note-pin" style={{
                    backgroundColor: '#37a',
                  }} />
                </div>
              </div>
            </GoogleMap>
          </div>
        </div>
        <div className="bottom-step-buttons">
          <a href="#new1">
            <div className="newPrevButton">
              {'< overview'}
            </div>
          </a>
          <a href="#" onClick={(e) => {
            e.preventDefault();
            this.props.onCreate();
          }}>
            <div className="newNextButton">
              publish!
            </div>
          </a>
        </div>
      </div>
    );
  },

});
