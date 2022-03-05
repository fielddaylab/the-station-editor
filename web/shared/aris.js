'use strict';

import update from 'immutability-helper';

export const ARIS_URL = 'https://fieldday-web.wcer.wisc.edu/station/server';

export const SIFTR_URL = window.location.origin + '/';

export class Game {
  constructor(json) {
    if (json != null) {
      this.game_id = parseInt(json.game_id);
      this.name = json.name;
      this.description = json.description;
      this.latitude = parseFloat(json.map_latitude);
      this.longitude = parseFloat(json.map_longitude);
      this.zoom = parseInt(json.map_zoom_level);
      this.siftr_url = json.siftr_url || null;
      this.is_siftr = parseInt(json.is_siftr) ? true : false;
      this.published = parseInt(json.published) ? true : false;
      this.moderated = parseInt(json.moderated) ? true : false;
      this.colors_id = parseInt(json.colors_id) || null;
      this.theme_id = parseInt(json.theme_id) || null;
      this.icon_media_id = parseInt(json.icon_media_id);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.prompt = json.prompt;
      this.password = json.password;
      this.type = json.type;
      this.map_show_labels = parseInt(json.map_show_labels) ? true : false;
      this.map_show_roads = parseInt(json.map_show_roads) ? true : false;
      this.map_type = json.map_type;
      this.field_id_preview = parseInt(json.field_id_preview) || null;
      this.field_id_pin = parseInt(json.field_id_pin) || null;
      this.field_id_caption = parseInt(json.field_id_caption) || null;
      this.force_new_format = parseInt(json.force_new_format) ? true : false;
    } else {
      this.game_id = null;
      this.name = null;
      this.description = null;
      this.latitude = null;
      this.longitude = null;
      this.zoom = null;
      this.siftr_url = null;
      this.is_siftr = null;
      this.published = null;
      this.moderated = null;
      this.colors_id = null;
      this.theme_id = null;
      this.icon_media_id = null;
      this.created = null;
      this.prompt = null;
      this.password = null;
      this.type = null;
      this.map_show_labels = null;
      this.map_show_roads = null;
      this.map_type = null;
      this.field_id_preview = null;
      this.field_id_pin = null;
      this.field_id_caption = null;
      this.force_new_format = null;
    }
  }

  createJSON() {
    return {
      game_id: this.game_id || void 0,
      name: this.name || '',
      description: this.description || '',
      map_latitude: this.latitude || 0,
      map_longitude: this.longitude || 0,
      map_zoom_level: this.zoom || 0,
      siftr_url: this.siftr_url,
      is_siftr: this.is_siftr,
      published: this.published,
      moderated: this.moderated,
      colors_id: this.colors_id,
      theme_id: this.theme_id,
      icon_media_id: this.icon_media_id,
      prompt: this.prompt,
      fields: this.fields,
      password: this.password,
      type: this.type,
      map_show_labels: this.map_show_labels,
      map_show_roads: this.map_show_roads,
      map_type: this.map_type,
      field_id_preview: this.field_id_preview,
      field_id_pin: this.field_id_pin,
      field_id_caption: this.field_id_caption,
    };
  }

  newFormat() {
    return this.field_id_preview || this.field_id_pin || this.field_id_caption || this.force_new_format;
  }
};

function deserializeGame(json) {
  var g;
  g = Object.assign(new Game, json);
  g.created = new Date(g.created);
  return g;
}

export class Colors {
  constructor(json) {
    if (json != null) {
      this.colors_id = parseInt(json.colors_id);
      this.name = json.name;
      this.tag_1 = json.tag_1;
      this.tag_2 = json.tag_2;
      this.tag_3 = json.tag_3;
      this.tag_4 = json.tag_4;
      this.tag_5 = json.tag_5;
      this.tag_6 = json.tag_6;
      this.tag_7 = json.tag_7;
      this.tag_8 = json.tag_8;
    }
  }

};

export class Theme {
  constructor(json) {
    if (json != null) {
      this.theme_id = parseInt(json.theme_id);
      this.name = json.name;
      this.gmaps_styles = json.gmaps_styles;
    }
  }

};

export class User {
  constructor(json) {
    if (json != null) {
      this.user_id = parseInt(json.user_id);
      this.display_name = json.display_name || json.user_name;
      this.media_id = parseInt(json.media_id);
    }
  }

};

export function arisHTTPS(x) {
  if (typeof x === 'string') {
    return x.replace('http://arisgames.org', 'https://arisgames.org');
  } else {
    return x;
  }
}

export class Tag {
  constructor(json) {
    var ref, ref1;
    if (json != null) {
      this.icon_url = arisHTTPS((ref = json.media) != null ? (ref1 = ref.data) != null ? ref1.url : void 0 : void 0);
      this.tag = json.tag;
      this.tag_id = parseInt(json.tag_id);
      this.game_id = parseInt(json.game_id);
      this.sort_index = parseInt(json.sort_index);
      this.color = json.color;
    } else {
      this.icon_url = null;
      this.tag = null;
      this.tag_id = null;
      this.game_id = null;
      this.sort_index = null;
      this.color = null;
    }
  }

  createJSON() {
    return {
      tag_id: this.tag_id || void 0,
      game_id: this.game_id,
      tag: this.tag,
      sort_index: this.sort_index,
      color: this.color || void 0
    };
  }

};

export class Comment {
  constructor(json) {
    if (json != null) {
      this.description = json.description;
      this.comment_id = parseInt(json.note_comment_id);
      this.user = new User(json.user);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.note_id = parseInt(json.note_id);
    }
  }

};

export class Note {
  constructor(json = null) {
    var comment, o, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9;
    if (json != null) {
      this.note_id = parseInt(json.note_id);
      this.game_id = parseInt(json.game_id);
      if (json.user != null) {
        this.user = new User(json.user);
      } else {
        this.user = new User({
          user_id: json.user_id,
          display_name: json.display_name
        });
      }
      this.description = json.description;
      this.media_id = parseInt((ref = json.media) != null ? (ref1 = ref.data) != null ? ref1.media_id : void 0 : void 0);
      this.photo_url = 0 === parseInt((ref2 = json.media) != null ? (ref3 = ref2.data) != null ? ref3.media_id : void 0 : void 0) || 0 === parseInt(json.media_id) ? null : arisHTTPS((ref4 = (ref5 = json.media) != null ? ref5.url : void 0) != null ? ref4 : json.media.data.url);
      this.thumb_url = 0 === parseInt((ref6 = json.media) != null ? (ref7 = ref6.data) != null ? ref7.media_id : void 0 : void 0) || 0 === parseInt(json.media_id) ? null : arisHTTPS((ref8 = (ref9 = json.media) != null ? ref9.big_thumb_url : void 0) != null ? ref8 : json.media.data.big_thumb_url);
      this.latitude = parseFloat(json.latitude);
      this.longitude = parseFloat(json.longitude);
      this.tag_id = parseInt(json.tag_id);
      this.created = new Date(json.created.replace(' ', 'T') + 'Z');
      this.player_liked = (json.player_liked != null) && !!(parseInt(json.player_liked));
      this.note_likes = parseInt(json.note_likes);
      this.comments = (function() {
        var i, len, ref10, ref11, ref12, ref13, results;
        ref12 = (ref10 = (ref11 = json.comments) != null ? ref11.data : void 0) != null ? ref10 : [];
        results = [];
        for (i = 0, len = ref12.length; i < len; i++) {
          o = ref12[i];
          comment = new Comment(o);
          if (!((ref13 = comment.description) != null ? ref13.match(/\S/) : void 0)) {
            continue;
          }
          results.push(comment);
        }
        return results;
      })();
      this.published = json.published;
    }
  }

};

function deserializeNote(json) {
  var n, o;
  n = Object.assign(new Note, json);
  n.user = Object.assign(new User, n.user);
  n.created = new Date(n.created);
  n.comments = (function() {
    var i, len, ref, results;
    ref = n.comments;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      o = ref[i];
      results.push(Object.assign(new Comment, o));
    }
    return results;
  })();
  return n;
}

export class Field {
  constructor(json = null) {
    var ref;
    if (json != null) {
      this.field_id = parseInt(json.field_id);
      this.game_id = parseInt(json.game_id);
      this.field_type = json.field_type;
      this.label = json.label;
      this.required = (ref = json.required) === true || ref === false ? json.required : !!(parseInt(json.required));
      this.sort_index = json.sort_index != null ? parseInt(json.sort_index) : null;
      this.options = json.options;
      this.min = parseFloat(json.min);
      this.max = parseFloat(json.max);
      this.step = parseFloat(json.step);
      this.min_color = json.min_color;
      this.max_color = json.max_color;
      this.quest_id = json.quest_id;
      // used during new game creation
      this.useAsPin = json.useAsPin;
      this.useOnCards = json.useOnCards;
      this.instruction = json.instruction;
    }
  }

};

export class FieldOption {
  constructor(json = null) {
    if (json != null) {
      this.field_option_id = parseInt(json.field_option_id);
      this.field_id = parseInt(json.field_id);
      this.game_id = parseInt(json.game_id);
      this.option = json.option;
      this.sort_index = json.sort_index != null ? parseInt(json.sort_index) : null;
      this.color = json.color;
      this.remnant_id = json.remnant_id;
    }
  }

};

export class FieldData {
  constructor(json = null) {
    if (json != null) {
      this.field_data_id = parseInt(json.field_data_id);
      this.note_id = parseInt(json.note_id);
      this.field_id = parseInt(json.field_id);
      this.field_data = json.field_data;
      this.media_id = parseInt(json.media_id);
      this.media = json.media;
      this.field_option_id = parseInt(json.field_option_id);
    }
  }

};

function sortByIndex(key_id) {
  return function(a, b) {
    if ((a.sort_index != null) && (b.sort_index != null)) {
      return a.sort_index - b.sort_index;
    } else if (a.sort_index != null) {
      return 1;
    } else if (b.sort_index != null) {
      return -1;
    } else {
      return a[key_id] - b[key_id];
    }
  };
}

// Handles Aris v2 authentication and API calls.
export class Aris {
  constructor() {
    var authJSON;
    authJSON = window.localStorage['aris-auth'];
    this.auth = authJSON != null ? JSON.parse(authJSON) : null;
  }

  // Given the JSON result of users.logIn, if it was successful,
  // creates and stores the authentication object.
  parseLogin({
      data: user,
      returnCode
    }) {
    var err;
    if (returnCode === 0 && user.user_id !== null) {
      this.auth = {
        user_id: parseInt(user.user_id),
        permission: 'read_write',
        key: user.read_write_key,
        username: user.user_name,
        display_name: user.display_name,
        media_id: user.media_id,
        email: user.email,
        bio: user.bio,
        url: user.url
      };
      try {
        return window.localStorage['aris-auth'] = JSON.stringify(this.auth);
      } catch (error) {
        err = error;
        // Private mode in iOS Safari disables local storage.
        // just don't bother remembering the auth.
        return null;
      }
    } else {
      return this.logout();
    }
  }

  // Logs in with a username and password, or logs in with the existing
  // known `auth` object if you pass `undefined` for the username and password.
  login(username, password, cb = (function() {})) {
    return this.call('users.logIn', {
      user_name: username,
      password: password,
      permission: 'read_write'
    }, (res) => {
      this.parseLogin(res);
      return cb();
    });
  }

  logout() {
    this.auth = null;
    return window.localStorage.removeItem('aris-auth');
  }

  // Calls a function from the Aris v2 API.
  // The callback receives the entire JSON-decoded response.
  call(func, json, cb) {
    var trySend, handleError;
    let req = new XMLHttpRequest();
    req.open("POST", `${ARIS_URL}/json.php/v2.${func}`, true);
    req.setRequestHeader("Content-Type", "application/json; charset=UTF-8");
    if (this.auth != null) {
      json = update(json, {auth: {$set: this.auth}});
    }
    json = update(json, {api: {$set: 2}});
    let jsonString = JSON.stringify(json);
    req.onload = () => {
      var ref;
      if (200 <= (ref = req.status) && ref < 400) {
        return cb(JSON.parse(req.responseText));
      } else {
        return handleError(req.status);
      }
    };
    req.onerror = () => {
      return handleError("Could not connect to Siftr");
    };
    let tries = 3;
    trySend = () => {
      if (req.readyState === req.OPENED) {
        return req.send(jsonString);
      } else {
        return cb({
          error: "Could not connect to Siftr",
          errorMore:
            "Make sure you can connect to siftr.org and arisgames.org."
        });
      }
    };
    handleError = error => {
      if (tries === 0) {
        return cb({ error });
      } else {
        tries -= 1;
        return trySend();
      }
    };
    return trySend();
  }

  // Perform an ARIS call, but then wrap a successful result with a class.
  callWrapped(func, json, cb, wrap) {
    return this.call(func, json, (result) => {
      if (result.returnCode === 0 && (result.data != null)) {
        result.data = wrap(result.data);
      }
      return cb(result);
    });
  }

  getGame(json, cb) {
    return this.callWrapped('games.getGame', json, cb, function(data) {
      return new Game(data);
    });
  }

  searchSiftrs(json, cb) {
    return this.callWrapped('games.searchSiftrs', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Game(o));
      }
      return results;
    });
  }

  siftrSearch(json, cb) {
    return this.callWrapped('notes.siftrSearch', json, cb, function(data) {
      var o;
      return {
        notes: (function() {
          var i, len, ref, results;
          ref = data.notes;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            o = ref[i];
            results.push(new Note(o));
          }
          return results;
        })(),
        map_notes: (function() {
          var i, len, ref, results;
          ref = data.map_notes;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            o = ref[i];
            results.push(new Note(o));
          }
          return results;
        })(),
        map_clusters: data.map_clusters
      };
    });
  }

  getTagsForGame(json, cb) {
    return this.callWrapped('tags.getTagsForGame', json, cb, function(data) {
      var o, tags;
      tags = (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = data.length; i < len; i++) {
          o = data[i];
          results.push(new Tag(o));
        }
        return results;
      })();
      tags.sort(sortByIndex('tag_id'));
      return tags;
    });
  }

  getUsersForGame(json, cb) {
    return this.callWrapped('users.getUsersForGame', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new User(o));
      }
      return results;
    });
  }

  getQuestsForGame(json, cb) {
    return this.callWrapped('quests.getQuestsForGame', json, cb, function(data) {
      return data;
    });
  }

  getPlaquesForGame(json, cb) {
    return this.callWrapped('plaques.getPlaquesForGame', json, cb, function(data) {
      return data;
    });
  }

  getFieldsForGame(json, cb) {
    return this.callWrapped('fields.getFieldsForGame', json, cb, function(data) {
      let fields = data.fields.map(o => new Field(o));
      fields.sort(sortByIndex('field_id'));
      let options = data.options.map(o => new FieldOption(o));
      fields.forEach(field => {
        field.options = options.filter(opt => field.field_id === opt.field_id);
        field.options.sort(sortByIndex('field_option_id'));
        field.guide = data.guides.find(g => parseInt(g.field_id) === parseInt(field.field_id));
      });
      return fields;
    });
  }

  getGamesForUser(json, cb) {
    return this.callWrapped('games.getGamesForUser', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Game(o));
      }
      return results;
    });
  }

  searchNotes(json, cb) {
    return this.callWrapped('notes.searchNotes', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Note(o));
      }
      return results;
    });
  }

  createGame(game, cb) {
    return this.callWrapped('games.createGame', game.createJSON(), cb, function(data) {
      return new Game(data);
    });
  }

  updateGame(game, cb) {
    return this.callWrapped('games.updateGame', game.createJSON(), cb, function(data) {
      return new Game(data);
    });
  }

  getColors(json, cb) {
    return this.callWrapped('colors.getColors', json, cb, function(data) {
      return new Colors(data);
    });
  }

  getTheme(json, cb) {
    return this.callWrapped('themes.getTheme', json, cb, function(data) {
      return new Theme(data);
    });
  }

  createTag(tag, cb) {
    return this.callWrapped('tags.createTag', tag.createJSON(), cb, function(data) {
      return new Tag(data);
    });
  }

  updateTag(json, cb) {
    return this.callWrapped('tags.updateTag', json, cb, function(data) {
      return new Tag(data);
    });
  }

  createNoteComment(json, cb) {
    return this.callWrapped('note_comments.createNoteComment', json, cb, function(data) {
      return new Comment(data);
    });
  }

  updateNoteComment(json, cb) {
    return this.callWrapped('note_comments.updateNoteComment', json, cb, function(data) {
      return new Comment(data);
    });
  }

  getNoteCommentsForNote(json, cb) {
    return this.callWrapped('note_comments.getNoteCommentsForNote', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Comment(o));
      }
      return results;
    });
  }

  getFieldDataForNote(json, cb) {
    return this.callWrapped('fields.getFieldDataForNote', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new FieldData(o));
      }
      return results;
    });
  }

  getFollowedGamesForUser(json, cb) {
    return this.callWrapped('games.getFollowedGamesForUser', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Game(o));
      }
      return results;
    });
  }

  getStaffPicks(json, cb) {
    return this.callWrapped('games.getStaffPicks', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Game(o));
      }
      return results;
    });
  }

  getNearbyGamesForPlayer(json, cb) {
    return this.callWrapped('client.getNearbyGamesForPlayer', json, cb, function(data) {
      var i, len, o, results;
      results = [];
      for (i = 0, len = data.length; i < len; i++) {
        o = data[i];
        results.push(new Game(o));
      }
      return results;
    });
  }

};
