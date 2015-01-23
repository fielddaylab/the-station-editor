(function() {
  var callAris, loadLogin, login, logout, selectPage;

  console.log('CoffeeScript loaded.');

  $.cookie.json = true;

  callAris = function(func, json, cb) {
    var req;
    if (cb == null) {
      cb = function(x) {
        window.arisResult = x;
        return console.log(x);
      };
    }
    req = new XMLHttpRequest;
    req.onreadystatechange = function() {
      if (req.readyState === 4) {
        if (req.status === 200) {
          return cb(JSON.parse(req.responseText));
        } else {
          return cb(false);
        }
      }
    };
    req.open('POST', "http://dev.arisgames.org/server/json.php/v2." + func, true);
    req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    return req.send(JSON.stringify(json));
  };

  loadLogin = function() {
    return window.auth = $.cookie('auth');
  };

  login = function(username, password, cb) {
    if (cb == null) {
      cb = (function() {});
    }
    return callAris('users.logIn', {
      user_name: username,
      password: password,
      permission: 'read_write'
    }, function(_arg) {
      var returnCode, user;
      user = _arg.data, returnCode = _arg.returnCode;
      if (returnCode === 0) {
        window.auth = {
          user_id: parseInt(user.user_id),
          permission: 'read_write',
          key: user.read_write_key
        };
        $.cookie('auth', window.auth);
      }
      return cb();
    });
  };

  logout = function() {
    window.auth = null;
    return $.removeCookie('auth');
  };

  selectPage = function(page) {
    $('.page').addClass('page-hidden');
    return $(page).removeClass('page-hidden');
  };

  $(document).ready(function() {
    $('#button-login').click(function() {
      return login($('#text-username').val(), $('#text-password').val(), function() {
        if (window.auth != null) {
          return selectPage('#page-list');
        }
      });
    });
    $('#button-logout').click(function() {
      logout();
      return selectPage('#page-login');
    });
    loadLogin();
    if (window.auth != null) {
      return selectPage('#page-list');
    } else {
      return selectPage('#page-login');
    }
  });

  window.callAris = callAris;

}).call(this);
