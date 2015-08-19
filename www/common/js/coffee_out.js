(function() {
  var Aris;

  Aris = (function() {
    function Aris() {
      var auth;
      this.storage = window.localStorage != null;
      this.auth = this.storage ? (auth = localStorage['aris-auth'], auth != null ? JSON.parse(auth) : null) : ($.cookie.json = true, $.cookie('aris-auth'));
    }

    Aris.prototype.parseLogin = function(_arg) {
      var returnCode, user;
      user = _arg.data, returnCode = _arg.returnCode;
      if (returnCode === 0 && user.user_id !== null) {
        this.auth = {
          user_id: parseInt(user.user_id),
          permission: 'read_write',
          key: user.read_write_key,
          username: user.user_name
        };
        if (this.storage) {
          return localStorage['aris-auth'] = JSON.stringify(this.auth);
        } else {
          return $.cookie('aris-auth', this.auth, {
            path: '/',
            expires: 365
          });
        }
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
      if (this.storage) {
        return localStorage.removeItem('aris-auth');
      } else {
        return $.removeCookie('aris-auth', {
          path: '/'
        });
      }
    };

    Aris.prototype.call = function(func, json, cb) {
      if (this.auth != null) {
        json.auth = this.auth;
      }
      return $.ajax({
        contentType: 'application/x-www-form-urlencoded',
        data: JSON.stringify(json),
        dataType: 'json',
        success: cb,
        error: function() {
          return cb(false);
        },
        processData: false,
        type: 'POST',
        url: "" + ARIS_URL + "/json.php/v2." + func
      });
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
  var appendTo, cordovaFixLinks, entityMap, escapeHTML, parseElement;

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
    var c, child, children, classes, id, p, tag, _i, _len, _ref;
    if (haml == null) {
      haml = '';
    }
    if (attrs == null) {
      attrs = {};
    }
    if (init == null) {
      init = (function() {});
    }
    _ref = parseElement(haml), tag = _ref.tag, classes = _ref.classes, id = _ref.id;
    for (_i = 0, _len = classes.length; _i < _len; _i++) {
      c = classes[_i];
      if (attrs["class"] == null) {
        attrs["class"] = '';
      }
      attrs["class"] += " " + c;
    }
    if (id != null) {
      attrs.id = id;
    }
    children = (function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = parents.length; _j < _len1; _j++) {
        p = parents[_j];
        p = $(p);
        child = $("<" + tag + " />", attrs);
        init(child);
        p.append(' ');
        p.append(child);
        p.append(' ');
        _results.push(child);
      }
      return _results;
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

  cordovaFixLinks = function() {
    var elt, url, _i, _j, _len, _len1, _ref, _ref1, _results;
    if (window.cordova != null) {
      _ref = $('.cordova-internal-link');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        elt = _ref[_i];
        elt.href = elt.href.replace(/\/$/g, '/index.html').replace(/\/\#/g, '/index.html#');
      }
      _ref1 = $('.cordova-external-link');
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        elt = _ref1[_j];
        if (!elt.cordovaFixed) {
          url = elt.href;
          elt.href = '#';
          $(elt).click(function() {
            return window.open(url, '_system');
          });
          _results.push(elt.cordovaFixed = true);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  window.cordovaFixLinks = cordovaFixLinks;

}).call(this);
