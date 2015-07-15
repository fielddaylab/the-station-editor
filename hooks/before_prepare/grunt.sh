#!/bin/bash
set -e
set -u

cd www/
npm install
grunt
