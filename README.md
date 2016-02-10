This top directory is for the Cordova app. The website itself lives in `web/`.
You must first run the Grunt build in the `web/` directory.

A script in the `hooks/` directory copies the necessary files from `web/` to `www/` for the Cordova app,
ignoring unused files like `node_modules` and non-minified JS.
