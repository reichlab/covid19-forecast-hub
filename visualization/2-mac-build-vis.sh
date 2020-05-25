#!/usr/bin/env bash

# Build flusight
set -e

# Change branding and metadata of website
#rm ./vis-master/config.yaml
cp ./config.yaml ./vis-master/config.yaml

# # Change statcounter snippet
# rm ./vis-master/src/assets/analytics.js
# mv ./analytics.js ./vis-master/src/assets/analytics.js

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

# Change text above map
# CDC FluSight Network Collaborative Ensemble
# sed -i "" 's/| Real-time <b>COVID-19 Death Forecasts<\/b>/a(v-bind:href="branding.parentUrl") CDC COVID-19 Forecast Project/' ./src/components/Panels.vue
# sed -i "" 's/Reich Lab/COVID-19/' ./src/components/Panels.vue
# sed -i "" '/computed/a\
# 			...mapGetters(["branding"]),' ./src/components/Panels.vue

# Change score description links
sed -i "" 's/reichlab\/flusight\/wiki\/Scoring#1-absolute-error/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js
sed -i "" 's/reichlab\/flusight\/wiki\/Scoring#2-log-score-single-bin/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js
sed -i "" 's/reichlab\/flusight\/wiki\/Scoring#3-log-score-multi-bin/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js

# Change max heap size
sed -i "" 's/node build\/build.js/node --max_old_space_size=6000 build\/build.js/' ./package.json

# Build the site
yarn run build
#cp -r ./dist/* ../../ # Copy to repo root
cd .. # in ./flusight-deploy
#rm -rf ./vis-master/data