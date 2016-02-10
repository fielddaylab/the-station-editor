#!/bin/bash
set -e
set -u

rm -rf www
git checkout www
rsync -av --progress web/* www \
  --exclude node_modules \
  --exclude coffee_out.js \
  --exclude browserify_out.js \
  --exclude minify_out.js.report.txt \
  --exclude \*.coffee \
  --exclude \*.rb \
  --exclude favicon.ico \
  --exclude README.md \
  --exclude shared \
  --exclude Makefile \
  --exclude package.json \
  --exclude somicro/disclaimer.jpg \
  --exclude somicro/preview.jpg
