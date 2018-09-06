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
      tab: 'focus'
    };
  },

  shouldComponentUpdate: function(nextProps, nextState) {
    // This prevents the map from jerking back.
    // The number comparisons are needed due to tiny floating point errors.
    if (this.props.editing !== nextProps.editing) return true;
    if (Math.abs(this.props.game.latitude - nextProps.game.latitude) > 0.0000001) return true;
    if (Math.abs(this.props.game.longitude - nextProps.game.longitude) > 0.0000001) return true;
    if (this.props.game.zoom !== nextProps.game.zoom) return true;
    if (this.props.game.type !== nextProps.game.type) return true;
    if (this.state.tab !== nextState.tab) return true;
    if (this.props.game.colors_id !== nextProps.game.colors_id) return true;
    if (this.props.game.theme_id !== nextProps.game.theme_id) return true;
    if (this.props.game.map_show_labels !== nextProps.game.map_show_labels) return true;
    if (this.props.game.map_show_roads !== nextProps.game.map_show_roads) return true;
    if (this.props.game.map_type !== nextProps.game.map_type) return true;
    return false;
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
    return make('div.newStepBox', () => {
      child('div.newStep3', () => {
        child('div.newStep3Controls', () => {
          child('div.newStep3Tabs', () => {
            var makeTab, makeTabDivider;
            makeTab = (tab, alt) => {
              return child('div.newStep3Tab', () => {
                child('a', {
                  href: '#',
                  alt: alt
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      this.setState({
                        tab: tab
                      });
                    }
                  });
                  return child('img', {
                    src: `../assets/icons/icon-${tab}.png`,
                    className: this.state.tab === tab ? '' : 'map-tab-off'
                  });
                });
                return child(`div.newStep3TabArrow${(this.state.tab === 'focus' ? '.newStep3GrayBG' : '')}`, () => {
                  if (this.state.tab === tab) {
                    return child('img', {
                      src: `../assets/icons/map-options-arrow${(tab === 'focus' ? '-gray' : '')}.png`
                    });
                  }
                });
              });
            };
            makeTabDivider = () => {
              return child('div.newStep3Tab.newStep3TabDividerBox', () => {
                child('div.newStep3TabDivider');
                return child(`div.newStep3TabArrow${(this.state.tab === 'focus' ? '.newStep3GrayBG' : '')}`);
              });
            };
            makeTab('focus', 'Focus');
            makeTabDivider();
            makeTab('theme', 'Theme');
            makeTabDivider();
            return makeTab('pins', 'Pins');
          });
          return child(`div.newStep3-control.newStep3-control-${this.state.tab}`, () => {
            var location, makeCard;
            switch (this.state.tab) {
              case 'theme':
                child('h2', () => {
                  raw('Select Map Theme');
                });
                makeCard = (image, text, selected, updater) => {
                  return child('a.theme-card', {
                    href: '#'
                  }, () => {
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        return this.props.onChange(update(this.props.game, updater));
                      }
                    });
                    child('img.theme-card-image', {
                      src: image
                    });
                    child('div.theme-card-name', () => {
                      raw(text);
                    });
                    return child('div.theme-card-check', () => {
                      return child('img', {
                        src: `../assets/icons/radio-${(selected ? 'on' : 'off')}.png`
                      });
                    });
                  });
                };
                Object.values(this.props.themes).forEach((theme) => {
                  var image, selected, updater;
                  image = (function() {
                    switch (theme.name) {
                      case 'Classic Siftr':
                        return 'classic';
                      case 'Aubergine':
                        return 'midnight';
                      case 'Retro':
                        return 'retro';
                      case 'Silver':
                        return 'silver';
                    }
                  })();
                  selected = this.props.game.theme_id === theme.theme_id && this.props.game.map_type === 'STREET';
                  updater = {
                    theme_id: {
                      $set: theme.theme_id
                    },
                    map_type: {
                      $set: 'STREET'
                    }
                  };
                  return makeCard(`../assets/icons/theme-${image}.png`, theme.name, selected, updater);
                });
                makeCard('../assets/icons/theme-satellite.png', 'Satellite', this.props.game.map_type === 'HYBRID', {
                  map_type: {
                    $set: 'HYBRID'
                  }
                });
                child('h2', () => {
                  raw('Map Options');
                });
                child(`a.form-multi-option.form-multi-option-${(this.props.game.map_show_labels ? 'on' : 'off')}`, {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.props.onChange(update(this.props.game, {
                        map_show_labels: {
                          $set: !this.props.game.map_show_labels
                        }
                      }));
                    }
                  });
                  child('span.form-multi-option-text', () => {
                    raw('Show labels');
                  });
                  return child('span.form-multi-option-switch', () => {
                    return child('span.form-multi-option-ball');
                  });
                });
                return child(`a.form-multi-option.form-multi-option-${(this.props.game.map_show_roads ? 'on' : 'off')}`, {
                  href: '#'
                }, () => {
                  props({
                    onClick: (e) => {
                      e.preventDefault();
                      return this.props.onChange(update(this.props.game, {
                        map_show_roads: {
                          $set: !this.props.game.map_show_roads
                        }
                      }));
                    }
                  });
                  child('span.form-multi-option-text', () => {
                    raw('Show roads');
                  });
                  return child('span.form-multi-option-switch', () => {
                    return child('span.form-multi-option-ball');
                  });
                });
              case 'pins':
                child('h2', () => {
                  raw('Select Category Theme');
                });
                return Object.values(this.props.colors).forEach((colors) => {
                  var j, rgbs;
                  rgbs = (function() {
                    var l, results;
                    if (colors != null) {
                      results = [];
                      for (j = l = 1; l <= 5; j = ++l) {
                        results.push(colors[`tag_${j}`]);
                      }
                      return results;
                    } else {
                      return [];
                    }
                  })();
                  return child('a.color-card', {
                    href: '#'
                  }, () => {
                    var l, len, rgb;
                    props({
                      onClick: (e) => {
                        e.preventDefault();
                        return this.props.onChange(update(this.props.game, {
                          colors_id: {
                            $set: colors.colors_id
                          }
                        }));
                      }
                    });
                    for (l = 0, len = rgbs.length; l < len; l++) {
                      rgb = rgbs[l];
                      child('div.color-card-pin', () => {
                        return child('div.siftr-map-note', () => {
                          return child('div.siftr-map-note-pin', {
                            style: {
                              backgroundColor: rgb
                            }
                          });
                        });
                      });
                    }
                    child('div.color-card-name', () => {
                      raw(colors != null ? colors.name : undefined);
                    });
                    return child('div.theme-card-check', () => {
                      return child('img', {
                        src: `../assets/icons/radio-${(this.props.game.colors_id === colors.colors_id ? 'on' : 'off')}.png`
                      });
                    });
                  });
                });
              case 'focus':
                child('h2', () => {
                  raw('Choose Map Focus');
                });
                location = this.props.game.type !== 'ANYWHERE';
                return child('div.newStep3FocusBlock', () => {
                  child('div.newStep3FocusButtons', () => {
                    var focusButton;
                    focusButton = (img, type) => {
                      return child('a', {
                        href: '#'
                      }, () => {
                        props({
                          onClick: (e) => {
                            e.preventDefault();
                            return this.props.onChange(update(this.props.game, {
                              type: {
                                $set: type
                              }
                            }));
                          }
                        });
                        return child('img', {
                          src: `../assets/icons/focus-${img}${(this.props.game.type === type ? '-on' : '')}.png`
                        });
                      });
                    };
                    focusButton('pins', 'ANYWHERE');
                    return focusButton('location', 'LOCATION');
                  });
                  child('div.newStep3FocusDivider');
                  if (this.props.game.type === 'ANYWHERE') {
                    child('h3', () => {
                      raw('Focus on Pins');
                    });
                    return child('p', () => {
                      raw('When someone views your Siftr, the map will start out zoomed out to encompass all of the pins in your Siftr.');
                    });
                  } else {
                    child('h3', () => {
                      raw('Focus on Location');
                    });
                    return child('p', () => {
                      raw('When someone views your Siftr, the map will start with the center point and zoom level you choose here.');
                    });
                  }
                });
            }
          });
        });
        return child('div.newStep3MapContainer', () => {
          var colors, i, l, results, rgb, styles;
          styles = this.getMapStyles();
          child(GoogleMap, {
            bootstrapURLKeys: {
              key: 'AIzaSyDlMWLh8Ho805A5LxA_8FgPOmnHI0AL9vw'
            },
            center: [this.props.game.latitude, this.props.game.longitude],
            zoom: Math.max(2, this.props.game.zoom),
            options: (maps) => {
              return {
                minZoom: 2,
                styles: styles,
                mapTypeId: (function() {
                  switch (this.props.game.map_type) {
                    case 'STREET':
                      return maps.MapTypeId.ROADMAP;
                    default:
                      return maps.MapTypeId.HYBRID;
                  }
                }).call(this)
              };
            },
            onChange: this.handleMapChange
          });
          colors = this.props.colors[this.props.game.colors_id];
          if (colors != null) {
            results = [];
            for (i = l = 1; l <= 5; i = ++l) {
              rgb = colors[`tag_${i}`];
              results.push(child('div.color-card-pin', () => {
                var coords;
                coords = [
                  { x: 269, y: 646 },
                  { x: 653, y: 1046 },
                  { x: 749, y: 124 },
                  { x: 896, y: 599 },
                  { x: 1472, y: 474 },
                ][i - 1];
                props({
                  style: {
                    position: 'absolute',
                    left: `${(coords.x / 1793) * 100}%`,
                    top: `${(coords.y / 1280) * 100}%`
                  }
                });
                return child('div.siftr-map-note', () => {
                  child('div.siftr-map-note-shadow');
                  return child('div.siftr-map-note-pin', {
                    style: {
                      backgroundColor: rgb
                    }
                  });
                });
              }));
            }
            return results;
          }
        });
      });
      if (this.props.editing) {
        return child('div.bottom-step-buttons', () => {
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
        });
      } else {
        return child('div.bottom-step-buttons', () => {
          child('a', {
            href: '#new1'
          }, () => {
            return child('div.newPrevButton', () => {
              raw('< setup');
            });
          });
          return child('a', {
            href: '#new4'
          }, () => {
            return child('div.newNextButton', () => {
              raw('data >');
            });
          });
        });
      }
    });
  },

  handleMapChange: function({
      center: {lat, lng},
      zoom
    }) {
    var game;
    game = update(this.props.game, {
      latitude: {
        $set: lat
      },
      longitude: {
        $set: lng
      },
      zoom: {
        $set: zoom
      }
    });
    return this.props.onChange(game);
  },

});
