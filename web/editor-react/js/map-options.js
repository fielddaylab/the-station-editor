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
    const editingCache = this.state.editCacheIndex != null ?
      this.props.game.caches[this.state.editCacheIndex] :
      null;

    const fieldNoteOptions = [].concat.apply([], this.props.game.fields.map(field =>
      field.noFieldNote ? [] : (field.options || [])
    ));

    return (
      <div className="newStepBox">
        <div className="newStep3">
          <div className="newStep3Controls">
            {
              editingStop ? (
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
                    maxCount={3}
                    media_id={[editingStop.media_id, editingStop.media_id_2, editingStop.media_id_3]}
                    uploadMedia={this.props.uploadMedia}
                    game={this.props.game}
                    aris={this.props.aris}
                    applyMedia={(media_ids) => {
                      this.props.onChange(update(this.props.game, {
                        plaques: {
                          [this.state.editPlaqueIndex]: {
                            media_id: {
                              $set: media_ids[0],
                            },
                            media_id_2: {
                              $set: media_ids[1],
                            },
                            media_id_3: {
                              $set: media_ids[2],
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
                        fieldNoteOptions.map(option =>
                          <option value={option.field_option_id} key={option.field_option_id}>
                            {option.option}
                          </option>
                        )
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
              ) : editingCache ? (
                <div className="tour-stop-edit">
                  <h2>
                    <img src="img/icon-tour-stop.png" style={{
                      width: 144 / 4,
                      height: 154 / 4,
                    }} />
                    <span>Cache:</span>
                  </h2>
                  <hr />
                  <label>
                    Cache Coordinates:
                    <input
                      type="text"
                      placeholder="Latitude"
                      value={editingCache.latitude}
                      onChange={e => this.props.onChange(update(this.props.game, {
                        caches: {
                          [this.state.editCacheIndex]: {
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
                      value={editingCache.longitude}
                      onChange={e => this.props.onChange(update(this.props.game, {
                        caches: {
                          [this.state.editCacheIndex]: {
                            longitude: {
                              $set: e.target.value,
                            },
                          },
                        },
                      }))}
                    />
                  </label>
                  <hr />
                  <div style={{
                    display: 'flex',
                    flexDirection: 'row',
                    alignItems: 'center',
                  }}>
                    <select style={{
                      fontSize: 20,
                      flex: 1,
                      marginRight: 10,
                    }} value={editingCache.field_option_id} onChange={(e) => {
                      this.props.onChange(update(this.props.game, {
                        caches: {
                          [this.state.editCacheIndex]: {
                            field_option_id: {
                              $set: e.target.value,
                            },
                          },
                        },
                      }));
                    }}>
                      {
                        fieldNoteOptions.map(option =>
                          <option value={option.field_option_id} key={option.field_option_id}>
                            {option.option}
                          </option>
                        )
                      }
                    </select>
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
                      this.props.onChange(update(this.props.game, {
                        caches: {
                          $splice: [[this.state.editCacheIndex, 1]],
                        },
                      }));
                      this.setState({editCacheIndex: null});
                    }}>
                      Delete cache
                    </a>
                  </p>
                </div>
              ) : null
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
                  mapTypeControl: true,
                  fullscreenControl: false,
                };
              }}
              onChange={({center, zoom}) => {
                this.setState({mapCenter: center});
              }}
              draggable={!this.state.draggingPin}
              onChildMouseDown={(childKey, childProps, mouse) => {
                this.setState({draggingPin: true});
                if (this.gmap && childKey[0] === 'c') {
                  this.stopCircles = (this.props.game.plaques || []).map(plaque =>
                    new this.gmap.maps.Circle({
                      strokeColor: 'black',
                      strokeOpacity: 0.6,
                      strokeWeight: 2,
                      map: this.gmap.map,
                      center: {lat: parseFloat(plaque.latitude), lng: parseFloat(plaque.longitude)},
                      radius: 15,
                    })
                  );
                }
              }}
              onChildMouseMove={(childKey, childProps, mouse) => {
                const pinType = childKey[0] === 'c' ? 'caches' : 'plaques';
                const pinIndex = parseInt(childKey.slice(1));
                this.props.onChange(update(this.props.game, {
                  [pinType]: {
                    [pinIndex]: {
                      latitude: {$set: mouse.lat},
                      longitude: {$set: mouse.lng},
                    },
                  },
                }));
              }}
              onChildMouseUp={(childKey, childProps, mouse) => {
                this.setState({draggingPin: false});
                if (this.stopCircles) {
                  this.stopCircles.forEach(c => c.setMap(null));
                  this.stopCircles = null;
                }
              }}
              onGoogleApiLoaded={gmap => {
                this.gmap = gmap;
              }}
            >
              {
                (this.props.game.plaques || []).map((plaque, i) =>
                  <div key={'p' + i}
                    lat={plaque.latitude}
                    lng={plaque.longitude}
                    onClick={() => this.setState({editPlaqueIndex: i, editCacheIndex: null})}
                    style={{position: 'relative'}}
                  >
                    {
                      this.state.editPlaqueIndex === i && (
                        <div style={{
                          width: 50,
                          height: 50,
                          boxSizing: 'border-box',
                          border: '2px solid rgb(101,88,245)',
                          left: -26,
                          top: -25,
                          zIndex: 1,
                          position: 'absolute',
                          borderRadius: 999,
                        }} />
                      )
                    }
                    <img src="img/icon-tour-stop-map.png" style={{
                      width: 144 * 0.25,
                      height: 154 * 0.25,
                      marginLeft: (144 * 0.25) * -0.5,
                      marginTop: (154 * 0.25) * -0.5,
                      position: 'relative',
                      zIndex: 2,
                    }} />
                  </div>
                )
              }
              {
                (this.props.game.caches || []).map((cache, i) =>
                  <div key={'c' + i}
                    lat={cache.latitude}
                    lng={cache.longitude}
                    onClick={() => this.setState({editCacheIndex: i, editPlaqueIndex: null})}
                    style={{position: 'relative'}}
                  >
                    {
                      this.state.editCacheIndex === i && (
                        <div style={{
                          width: 50,
                          height: 50,
                          boxSizing: 'border-box',
                          border: '2px solid rgb(159,96,43)',
                          left: -25,
                          top: -25,
                          zIndex: 1,
                          position: 'absolute',
                          borderRadius: 999,
                        }} />
                      )
                    }
                    <img src="img/icon-chest.png" style={{
                      width: 62 * 0.5,
                      height: 46 * 0.5,
                      marginLeft: (62 * 0.5) * -0.5,
                      marginTop: (46 * 0.5) * -0.5,
                      position: 'relative',
                      zIndex: 2,
                    }} />
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
                editCacheIndex: null,
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
            <a href="#" onClick={e => {
              e.preventDefault();
              this.props.onChange(update(this.props.game, {
                caches: {
                  $push: [{
                    latitude: this.state.mapCenter.lat,
                    longitude: this.state.mapCenter.lng,
                    field_option_id: fieldNoteOptions[0].field_option_id,
                  }],
                },
              }));
              this.setState({
                editPlaqueIndex: null,
                editCacheIndex: this.props.game.caches.length, // index of newly pushed cache
              })
            }} style={{
              position: 'absolute',
              color: 'white',
              backgroundColor: 'rgb(96,95,236)',
              right: 15,
              top: 73,
              padding: 8,
              paddingLeft: 15,
              paddingRight: 15,
              borderRadius: 4,
            }}>
              Add Cache
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
              {
                parseInt(this.props.game.quest_id) ? (
                  <div />
                ) : (
                  <a href="#" onClick={(e) => {
                    e.preventDefault();
                    this.props.onCreate();
                  }}>
                    <div className="newNextButton">
                      publish!
                    </div>
                  </a>
                )
              }
            </div>
          )
        }
      </div>
    );
  },

});
