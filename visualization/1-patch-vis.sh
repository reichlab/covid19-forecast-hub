#!/usr/bin/env bash

# Script for patching metadata files in flusight.
# Mostly we are adding information about the FluSightNetwork ensemble to show
# up in the website.
# NOTE: This script is only run once on the cloned flusight repo.
set -e

# Change branding and metadata of website
rm ./vis-master/config.yaml -f
cp ./config.yaml ./vis-master

# # Change statcounter snippet
# rm ./vis-master/src/assets/analytics.js -f
# cp ./analytics.js ./vis-master/src/assets/analytics.js

cd ./vis-master

# Clean footer
sed -i '/.modal#dis/,/footer.modal-card/d' ./src/components/Foot.vue
sed -ni '/and dis/{s/.*//;x;d;};x;p;${x;p;}' ./src/components/Foot.vue
sed -i '/let showModa/,/})$/d' ./src/components/Foot.vue

# Clean navbar
sed -i '/a($/,/logo")$/d' ./src/components/Navbar.vue
sed -i '/padding-left/,/border-left-width/d' ./src/components/Navbar.vue
sed -i '/href="branding.tweetUrl"/,/span Tweet/d' ./src/components/Navbar.vue
sed -i 's/span.brand.title-text {{ branding.title }}/a.brand.title-text(v-bind:href="branding.parentUrl") {{ branding.title }}/'\
    ./src/components/Navbar.vue

# Change text above map
# CDC COVID-19
sed -i 's/| Real-time <b>COVID-19 Forecasts<\/b>/a(v-bind:href="branding.parentUrl") CDC COVID-19 Forecast Project/' ./src/components/Panels.vue
sed -i 's/CDC FluSight Challenge/COVID-19/' ./src/components/Panels.vue
sed -i "/computed/a...mapGetters(['branding'])," ./src/components/Panels.vue

# Change score description links
sed -i 's/reichlab\/flusight\/wiki\/Scoring#1-absolute-error/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js
sed -i 's/reichlab\/flusight\/wiki\/Scoring#2-log-score-single-bin/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js
sed -i 's/reichlab\/flusight\/wiki\/Scoring#3-log-score-multi-bin/FluSightNetwork\/cdc-flusight-ensemble\/wiki\/Evaluation/' ./src/store/modules/scores.js

# Change max heap size
sed -i 's/node build\/build.js/node --max_old_space_size=6000 build\/build.js/' ./package.json

cd ..
