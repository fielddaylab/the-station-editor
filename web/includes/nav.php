<script type="text/javascript">

function arisCall(func, json, cb) {
  var trySend, handleError;
  var req = new XMLHttpRequest();
  req.open("POST", "../server/json.php/v2." + func, true);
  req.setRequestHeader("Content-Type", "application/json; charset=UTF-8");
  var jsonString = JSON.stringify(json);
  req.onload = function(){
    var ref;
    if (200 <= (ref = req.status) && ref < 400) {
      return cb(JSON.parse(req.responseText));
    } else {
      return handleError(req.status);
    }
  };
  req.onerror = function(){
    return handleError("Could not connect to Station");
  };
  var tries = 3;
  trySend = function(){
    if (req.readyState === req.OPENED) {
      return req.send(jsonString);
    } else {
      return cb({
        error: "Could not connect to Station",
        errorMore:
          "Make sure you can connect to the station server (Usually at ./server)"
      });
    }
  };
  handleError = function(error){
    if (tries === 0) {
      return cb({ error });
    } else {
      tries -= 1;
      return trySend();
    }
  };
  return trySend();
}

function updateSiftrNav() {
  var authJSON = window.localStorage['aris-auth'];
  if (authJSON) {
    authJSON = JSON.parse(authJSON);
    var name = authJSON.display_name || authJSON.username;
    var media_id = parseInt(authJSON.media_id);
    arisCall('media.getMedia', {media_id: media_id}, function(result){
      var src = undefined;
      if (result.data && result.returnCode === 0) {
        src = result.data.thumb_url.replace('http://', 'https://');
      }
      document.getElementById('nav-login').classList.add('nav-hide');
      document.getElementById('nav-profile').classList.remove('nav-hide');
      var link = document.getElementById('nav-profile-link');
      link.innerHTML = name;
      link.appendChild(document.createTextNode(' '));
      var img = new Image();
      img.src = src;
      img.classList.add('nav-profile-img');
      link.appendChild(img);
    })
  } else {
    document.getElementById('nav-login').classList.remove('nav-hide');
    document.getElementById('nav-profile').classList.add('nav-hide');
  }
}

document.addEventListener('DOMContentLoaded', updateSiftrNav);

</script>
<nav class="main-nav">
  <div class="nav-contents">
    <ul class="nav-items" id="stemports-breadcrumbs">
    </ul>
    <ul class="nav-items">
      <li id="nav-login"><a href="./editor/#">login</a></li>
      <li id="nav-profile" class="nav-hide"><a href="/editor/#profile" id="nav-profile-link">profile</a></li>
    </ul>
    <img class="smily-pin" src="/assets/icons/smily-pin.png">
  </div>
  <span class="mobile-nav-open mobile-nav-toggle"></span>
</nav>
