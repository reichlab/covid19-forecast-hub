#!/usr/bin/env bash

# Build flusight
set -e

# Change branding and metadata of website
cp ./config.yaml ./vis-master/config.yaml

# Updating comment to trigger new travis build
cd ./vis-master

# Clean footer
sed -i "" '/.modal#dis/,/footer.modal-card/d' ./src/components/Foot.vue
sed -ni "" '/and dis/{s/.*//;x;d;};x;p;${x;p;}' ./src/components/Foot.vue
sed -i "" '/let showModa/,/})$/d' ./src/components/Foot.vue

# Clean navbar
sed -i "" '/a($/,/logo")$/d' ./src/components/Navbar.vue
sed -i "" '/padding-left/,/border-left-width/d' ./src/components/Navbar.vue
sed -i "" '/href="branding.tweetUrl"/,/span Tweet/d' ./src/components/Navbar.vue
sed -i "" 's/span.brand.title-text {{ branding.title }}/a.brand.title-text(v-bind:href="branding.parentUrl") {{ branding.title }}/'\
    ./src/components/Navbar.vue

# Change max heap size
sed -i "" 's/node build\/build.js/node --max_old_space_size=6000 build\/build.js/' ../../package.json

# Build the site
yarn run build
#cp -r ./dist/* ../../ # Copy to repo root
cd .. # in ./flusight-deploy