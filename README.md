# Siftr

A [Field Day](http://fielddaylab.org) experiment.

Some icons designed by [Freepik](http://www.flaticon.com/authors/freepik) ([free license](http://file005.flaticon.com/downloads/license/license.pdf))
and [Tina Mailhot-Roberge](http://vervex.ca/) ([CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)).

## Instructions

This top directory is for the Cordova app. The website itself lives in `web/`.
You must first run the Grunt build in the `web/` directory.
(You can do this with `make`, from inside or outside `web/`.)

A script in the `hooks/` directory copies the necessary files from `web/` to `www/` for the Cordova app,
ignoring unused files like `node_modules` and non-minified JS.

```
# to build:
brew install npm closure-compiler # or your system's package manager
[sudo] npm install -g grunt
make

# to deploy over rsync:
make deploy

# to build android app:
cordova platform add android
cordova build android
```
