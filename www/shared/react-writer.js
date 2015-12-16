(function() {
  var React, child, k, make, parseElement, props, raw, update, v, _ref,
    __slice = [].slice;

  React = require('react');

  update = require('react-addons-update');

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

  make = function(fact, arg1, arg2) {
    var classes, factory, fn, id, me, prevParent, startProps, tag, _ref;
    if (arg1 != null) {
      if (typeof arg1 === 'function') {
        startProps = {};
        fn = arg1;
      } else {
        startProps = arg1;
        fn = arg2 != null ? arg2 : (function() {});
      }
    } else {
      startProps = {};
      fn = (function() {});
    }
    prevParent = window.theParent;
    if (typeof fact === 'string') {
      _ref = parseElement(fact), tag = _ref.tag, classes = _ref.classes, id = _ref.id;
      factory = tag;
      startProps = update(startProps, {
        className: classes.length > 0 ? {
          $apply: function(oldClasses) {
            return "" + (oldClasses != null ? oldClasses : '') + " " + (classes.join(' '));
          }
        } : {},
        id: id != null ? {
          $set: id
        } : {}
      });
    } else {
      factory = fact;
    }
    window.theParent = {
      props: startProps,
      children: []
    };
    fn();
    me = React.createElement.apply(React, [factory, window.theParent.props].concat(__slice.call(window.theParent.children)));
    window.theParent = prevParent;
    return me;
  };

  child = function() {
    var args, me;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    me = make.apply(null, args);
    return window.theParent = update(window.theParent, {
      children: {
        $push: [me]
      }
    });
  };

  raw = function() {
    var raws;
    raws = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return window.theParent = update(window.theParent, {
      children: {
        $push: raws
      }
    });
  };

  props = function(obj) {
    return window.theParent = update(window.theParent, {
      props: {
        $merge: obj
      }
    });
  };

  _ref = {
    make: make,
    child: child,
    raw: raw,
    props: props
  };
  for (k in _ref) {
    v = _ref[k];
    exports[k] = v;
  }

}).call(this);
