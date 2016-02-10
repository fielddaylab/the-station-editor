#!/bin/bash
set -e
set -u

rm -rf www
git checkout www
rsync -av --progress web/* www --exclude node_modules --exclude coffee_out.js --exclude browserify_out.js --exclude \*.coffee
