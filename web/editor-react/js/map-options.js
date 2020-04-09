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

export const MapOptions = createClass({
  displayName: 'MapOptions',

  getInitialState: function() {
    return {
      mapCenter: {
        lat: this.props.game.latitude,
        lng: this.props.game.longitude,
      },
      draggingPin: false,
    };
  },

  getMapStyles: function(props = this.props) {
    var styles, theme;
    styles = [];
    if (((theme = props.themes[props.game.theme_id]) != null) && props.game.map_type === 'STREET') {
      styles = JSON.parse(theme.gmaps_styles);
    }
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
            {
              this.state.editPlaqueIndex != null && (
                <div>
                  <p>Editing Stop</p>
                  <input
                    type="text"
                    placeholder="Title"
                    value={this.props.game.plaques[this.state.editPlaqueIndex].name}
                    onChange={e => this.props.onChange(update(this.props.game, {
                      plaques: {
                        [this.state.editPlaqueIndex]: {
                          name: {
                            $set: e.target.value,
                          },
                        },
                      },
                    }))}
                  />
                  <textarea
                    placeholder="Description"
                    value={this.props.game.plaques[this.state.editPlaqueIndex].description}
                    onChange={e => this.props.onChange(update(this.props.game, {
                      plaques: {
                        [this.state.editPlaqueIndex]: {
                          description: {
                            $set: e.target.value,
                          },
                        },
                      },
                    }))}
                  />
                  <p>
                    <a href="#" onClick={(e) => {
                      e.preventDefault();
                      this.setState({editPlaqueIndex: null});
                    }}>
                      Close
                    </a>
                  </p>
                </div>
              )
            }
            <p>
              <a href="#" onClick={(e) => {
                e.preventDefault();
                this.props.onChange(update(this.props.game, {
                  plaques: {
                    $push: [{
                      name: 'A Tour Stop',
                      description: '',
                      latitude: this.state.mapCenter.lat,
                      longitude: this.state.mapCenter.lng,
                    }],
                  },
                }));
              }}>
                Add Stop
              </a>
            </p>
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
                  mapTypeId: (function() {
                    switch (this.props.game.map_type) {
                      case 'STREET':
                        return maps.MapTypeId.ROADMAP;
                      default:
                        return maps.MapTypeId.HYBRID;
                    }
                  }).call(this)
                };
              }}
              onChange={({center, zoom}) => {
                this.setState({mapCenter: center});
              }}
              draggable={!this.state.draggingPin}
              onChildMouseDown={(childKey, childProps, mouse) => {
                this.setState({draggingPin: true});
              }}
              onChildMouseMove={(childKey, childProps, mouse) => {
                this.props.onChange(update(this.props.game, {
                  plaques: {
                    [childKey]: {
                      latitude: {$set: mouse.lat},
                      longitude: {$set: mouse.lng},
                    },
                  },
                }));
              }}
              onChildMouseUp={(childKey, childProps, mouse) => {
                this.setState({draggingPin: false});
              }}
            >
              {
                this.props.game.plaques.map((plaque, i) =>
                  <div key={i}
                    className="color-card-pin"
                    lat={plaque.latitude}
                    lng={plaque.longitude}
                    onClick={() => this.setState({editPlaqueIndex: i})}
                  >
                    <div className="siftr-map-note">
                      <div className="siftr-map-note-shadow" />
                      <div className="siftr-map-note-pin" style={{
                        backgroundColor: '#37a',
                      }} />
                    </div>
                  </div>
                )
              }
            </GoogleMap>
          </div>
        </div>
        {
          this.props.editing ? (
            make('div.bottom-step-buttons', () => {
              child('a', {
                href: '#edit' + this.props.game.game_id
              }, () => {
                return child('div.newPrevButton', () => {
                  raw('< settings');
                });
              });
              return child('a', {
                href: '#form' + this.props.game.game_id
              }, () => {
                return child('div.newNextButton', () => {
                  raw('data >');
                });
              });
            })
          ) : (
            make('div.bottom-step-buttons', () => {
              child('a', {
                href: '#new2'
              }, () => {
                return child('div.newPrevButton', () => {
                  raw('< observations');
                });
              });
              return child('a', {
                href: '#new4'
              }, () => {
                return child('div.newNextButton', () => {
                  raw('field notes >');
                });
              });
            })
          )
        }
      </div>
    );
  },

});
