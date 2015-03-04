(function() {
  var Aris;

  Aris = (function() {
    function Aris() {
      $.cookie.json = true;
      this.auth = $.cookie('aris-auth');
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
        return $.cookie('aris-auth', this.auth, {
          path: '/'
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
      req.open('POST', "" + ARIS_URL + "/json.php/v2." + func, true);
      req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      return req.send(JSON.stringify(json));
    };

    return Aris;

  })();

  window.Aris = Aris;

}).call(this);

(function() {
  window.SIFTR_URL = 'http://siftr.org/v2/';

  window.ARIS_URL = 'http://dev.arisgames.org/server/';

}).call(this);

(function() {
  var appendTo, parseElement;

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

  appendTo = function(parent, haml, attrs, init) {
    var c, child, classes, id, tag, _i, _len, _ref;
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
    child = $("<" + tag + " />", attrs);
    init(child);
    parent.append(' ');
    parent.append(child);
    parent.append(' ');
    return child;
  };

  window.appendTo = appendTo;

}).call(this);
