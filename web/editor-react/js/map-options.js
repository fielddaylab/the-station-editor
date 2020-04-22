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
    const editingStop = this.state.editPlaqueIndex != null ?
      this.props.game.plaques[this.state.editPlaqueIndex] :
      null;

    return (
      <div className="newStepBox">
        <div className="newStep3">
          <div className="newStep3Controls">
            {
              editingStop && (
                <div className="tour-stop-edit">
                  <h2>
                    <img src="img/icon-tour-stop.png" style={{
                      width: 144 / 4,
                      height: 154 / 4,
                    }} />
                    <span>Tour Stop:</span>
                  </h2>
                  <hr />
                  <label>
                    Tour Stop Title:
                    <input
                      type="text"
                      placeholder="eg: Aspen Tree"
                      value={editingStop.name}
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
                  </label>
                  <label>
                    Tour Stop Summary:
                    <textarea
                      placeholder="Describe your tour stop"
                      value={editingStop.description}
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
                  </label>
                  <label>
                    Tour Stop Coordinates:
                    <input
                      type="text"
                      placeholder="Latitude"
                      value={editingStop.latitude}
                      onChange={e => this.props.onChange(update(this.props.game, {
                        plaques: {
                          [this.state.editPlaqueIndex]: {
                            latitude: {
                              $set: e.target.value,
                            },
                          },
                        },
                      }))}
                    />
                    <input
                      type="text"
                      placeholder="Longitude"
                      value={editingStop.longitude}
                      onChange={e => this.props.onChange(update(this.props.game, {
                        plaques: {
                          [this.state.editPlaqueIndex]: {
                            longitude: {
                              $set: e.target.value,
                            },
                          },
                        },
                      }))}
                    />
                  </label>
                  <MediaSelect
                    media={editingStop.media}
                    media_id={editingStop.media_id}
                    uploadMedia={this.props.uploadMedia}
                    game={this.props.game}
                    aris={this.props.aris}
                    applyMedia={(media) => {
                      this.props.onChange(update(this.props.game, {
                        plaques: {
                          [this.state.editPlaqueIndex]: {
                            media: {
                              $set: media, // includes url for displaying
                            },
                            media_id: {
                              $set: media.media_id, // to actually set in database
                            },
                          },
                        },
                      }));
                    }}
                  />
                  <hr />
                  <p>Attach Field Notes to stop:</p>
                  <ul>
                    {
                      (editingStop.fieldNotes || []).map(fieldNoteID => {
                        let matchOption = null;
                        this.props.game.fields.forEach(field => {
                          (field.options || []).forEach(option => {
                            if (option.field_option_id === fieldNoteID) {
                              matchOption = option;
                            }
                          });
                        });
                        if (matchOption) {
                          return (
                            <li key={matchOption.field_option_id}>
                              {matchOption.option}
                              <a href="#" onClick={e => {
                                e.preventDefault();
                                this.props.onChange(update(this.props.game, {
                                  plaques: {
                                    [this.state.editPlaqueIndex]: {
                                      fieldNotes: {
                                        $apply: (fieldNotes =>
                                          fieldNotes.filter(fn => fn !== fieldNoteID)
                                        ),
                                      },
                                    },
                                  },
                                }));
                              }}>
                                <img src="img/icon-delete.png" style={{
                                  width: 62 / 2,
                                  height: 62 / 2,
                                  marginLeft: 10,
                                  verticalAlign: 'middle',
                                }} />
                              </a>
                            </li>
                          );
                        }
                      }).filter(x => x)
                    }
                  </ul>
                  <div style={{
                    display: 'flex',
                    flexDirection: 'row',
                    alignItems: 'center',
                  }}>
                    <select style={{
                      fontSize: 20,
                      flex: 1,
                      marginRight: 10,
                    }} ref="selectFieldNote">
                      {
                        [].concat.apply([], this.props.game.fields.map(field =>
                          (field.options || []).map(option =>
                            <option value={option.field_option_id} key={option.field_option_id}>
                              {option.option}
                            </option>
                          )
                        ))
                      }
                    </select>
                    <a href="#" style={{
                      color: 'rgb(101,88,245)',
                      border: '2px solid rgb(199,194,252)',
                      padding: 10,
                      paddingTop: 6,
                      paddingBottom: 6,
                      borderRadius: 4,
                    }} onClick={e => {
                      e.preventDefault();
                      const fieldNoteID = parseInt(this.refs.selectFieldNote.value);
                      this.props.onChange(update(this.props.game, {
                        plaques: {
                          [this.state.editPlaqueIndex]: {
                            $apply: (plaque => {
                              if (plaque.fieldNotes && plaque.fieldNotes.indexOf(fieldNoteID) !== -1) {
                                return plaque; // don't add duplicate
                              }
                              if (plaque.fieldNotes) {
                                return update(plaque, {fieldNotes: {$push: [fieldNoteID]}});
                              } else {
                                return update(plaque, {fieldNotes: {$set: [fieldNoteID]}});
                              }
                            }),
                          },
                        },
                      }));
                    }}>
                      Add note +
                    </a>
                  </div>
                  <hr />
                  <p>
                    <a href="#" style={{
                      color: 'rgb(101,88,245)',
                      border: '2px solid rgb(199,194,252)',
                      padding: 10,
                      paddingTop: 6,
                      paddingBottom: 6,
                      borderRadius: 4,
                    }} onClick={e => {
                      e.preventDefault();
                      const fieldNoteID = parseInt(this.refs.selectFieldNote.value);
                      this.props.onChange(update(this.props.game, {
                        plaques: {
                          $splice: [[this.state.editPlaqueIndex, 1]],
                        },
                      }));
                      this.setState({editPlaqueIndex: null});
                    }}>
                      Delete tour stop
                    </a>
                  </p>
                </div>
              )
            }
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
                  }).call(this),
                  fullscreenControl: false,
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
                (this.props.game.plaques || []).map((plaque, i) =>
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
            <a href="#" onClick={e => {
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
              this.setState({
                editPlaqueIndex: this.props.game.plaques.length, // index of newly pushed stop
              })
            }} style={{
              position: 'absolute',
              color: 'white',
              backgroundColor: 'rgb(96,95,236)',
              right: 15,
              top: 15,
              padding: 8,
              paddingLeft: 15,
              paddingRight: 15,
              borderRadius: 4,
            }}>
              Add Tour Stop
            </a>
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
            <div className="bottom-step-buttons">
              <a href="#quest4">
                <div className="newPrevButton">
                  {'< field notes'}
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
          )
        }
      </div>
    );
  },

});
