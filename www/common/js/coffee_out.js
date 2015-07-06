(function() {
  var Aris;

  Aris = (function() {
    function Aris() {
      $.cookie.json = true;
      this.auth = $.cookie('aris-auth');
    }

    Aris.prototype.parseLogin = function(arg) {
      var returnCode, user;
      user = arg.data, returnCode = arg.returnCode;
      if (returnCode === 0 && user.user_id !== null) {
        this.auth = {
          user_id: parseInt(user.user_id),
          permission: 'read_write',
          key: user.read_write_key,
          username: user.user_name
        };
        return $.cookie('aris-auth', this.auth, {
          path: '/',
          expires: 365
        });
      } else {
        return this.logout();
      }
    };

    Aris.prototype.login = function(username, password, cb) {
      if (cb == null) {
        cb = (function() {});
      }
      return this.call('users.logIn', {
        user_name: username,
        password: password,
        permission: 'read_write'
      }, (function(_this) {
        return function(res) {
          _this.parseLogin(res);
          return cb();
        };
      })(this));
    };

    Aris.prototype.logout = function() {
      this.auth = null;
      return $.removeCookie('aris-auth', {
        path: '/'
      });
    };

    Aris.prototype.call = function(func, json, cb) {
      var req;
      if (this.auth != null) {
        json.auth = this.auth;
      }
      req = new XMLHttpRequest;
      req.onreadystatechange = (function(_this) {
        return function() {
          if (req.readyState === 4) {
            if (req.status === 200) {
              return cb(JSON.parse(req.responseText));
            } else {
              return cb(false);
            }
          }
        };
      })(this);
      req.open('POST', ARIS_URL + "/json.php/v2." + func, true);
      req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      return req.send(JSON.stringify(json));
    };

    return Aris;

  })();

  window.Aris = Aris;

}).call(this);

(function() {
  window.SIFTR_URL = window.location.origin + '/';

  window.ARIS_URL = 'http://arisgames.org/server/';

}).call(this);

(function() {
  var appendTo, entityMap, escapeHTML, parseElement;

  parseElement = function(str) {
    var classes, eatWord, id, tag;
    eatWord = function() {
      var dot, hash, word;
      hash = str.indexOf('#');
      dot = str.indexOf('.');
      if (hash === -1) {
        hash = 9999;
      }
      if (dot === -1) {
        dot = 9999;
      }
      word = str.slice(0, Math.min(hash, dot));
      str = str.slice(word.length);
      return word;
    };
    tag = eatWord() || 'div';
    classes = [];
    id = null;
    while (str !== '') {
      if (str[0] === '.') {
        str = str.slice(1);
        classes.push(eatWord());
      } else if (str[0] === '#') {
        str = str.slice(1);
        id = eatWord();
      } else {
        return false;
      }
    }
    return {
      tag: tag,
      classes: classes,
      id: id
    };
  };

  appendTo = function(parents, haml, attrs, init) {
    var c, child, children, classes, i, id, len, p, ref, tag;
    if (haml == null) {
      haml = '';
    }
    if (attrs == null) {
      attrs = {};
    }
    if (init == null) {
      init = (function() {});
    }
    ref = parseElement(haml), tag = ref.tag, classes = ref.classes, id = ref.id;
    for (i = 0, len = classes.length; i < len; i++) {
      c = classes[i];
      if (attrs["class"] == null) {
        attrs["class"] = '';
      }
      attrs["class"] += " " + c;
    }
    if (id != null) {
      attrs.id = id;
    }
    children = (function() {
      var j, len1, results;
      results = [];
      for (j = 0, len1 = parents.length; j < len1; j++) {
        p = parents[j];
        p = $(p);
        child = $("<" + tag + " />", attrs);
        init(child);
        p.append(' ');
        p.append(child);
        p.append(' ');
        results.push(child);
      }
      return results;
    })();
    if (children.length === 1) {
      return $(children[0]);
    } else {
      return $(children);
    }
  };

  window.appendTo = appendTo;

  entityMap = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
    '/': '&#x2F;'
  };

  escapeHTML = function(str) {
    return String(str).replace(/[&<>"'\/]/g, function(s) {
      return entityMap[s];
    });
  };

  window.escapeHTML = escapeHTML;

}).call(this);
