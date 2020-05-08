<style lang="scss">
.disclaimer-subtitle {
  margin-top: -10px;
  padding-top: 0;
  font-size: 12px;
  color: #696969;
}
#scores {
  padding: 5px 10px;

  a {
    color: #333;
    &:hover {
      text-decoration: underline;
    }
  }
  .score-body {
    margin: 10px 0;
    max-height: 450px;
    overflow-y: scroll;

    .bold {
      font-weight: bold;
    }
  }

  .score-footer {
    margin-top: 20px;
    color: gray;
    font-size: 14px;
    a {
      color: gray;
      text-decoration: underline;
      &:hover {
        color: #333;
      }
    }
  }

  .score-header {
    .score-btn {
      margin: 0 2px;
    }

    .score-title {
      font-size: 18px;
      font-weight: 300;
      margin-left: 10px;
    }
  }
}
</style>

<template lang="pug">
div
  // Main plotting div
  .tabs.is-small
    ul
      li(v-bind:class="[showTimeChart ? 'is-active' : '']" v-on:click="displayTimeChart")
        a Time Chart
  .disclaimer-subtitle
    | The <a href="https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/COVIDhub-ensemble/metadata-COVIDhub-ensemble.txt" target="_blank">ensemble</a> forecast combines models unconditional on particular interventions being in place with those conditional on certain social distancing measures continuing. To ensure consistency, only models with 4 week-ahead forecasts ahead are included in the ensemble.
  .container
    #chart-right(v-show="!showScoresPanel")

    #scores(v-show="showScoresPanel")
      .score-header
        span
          a.score-btn.button.is-small.prev-score-btn(v-bind:class="[prevScoreActive ? '' : 'is-disabled']" v-on:click="selectPrevScore")
            span.icon.is-small
              i.fa.fa-arrow-left
        span
          a.score-btn.button.is-small.next-score-btn(v-bind:class="[nextScoreActive ? '' : 'is-disabled']" v-on:click="selectNextScore")
            span.icon.is-small
              i.fa.fa-arrow-right
        span.score-title
          a(v-bind:href="selectedScoresMeta.url" target="_blank") {{ selectedScoresMeta.name }}
      .score-body
        table.table.is-striped.is-bordered#score-table
          thead
            tr
              th Model
              th(v-for="hd in scoresHeaders") {{ hd }}
          tbody
            tr(v-for="(i, id) in modelIds")
              td
                a(v-bind:href="modelMeta[i].url" target="_blank") {{ id }}
              td(v-for="(j, scr) in selectedScoresData[i]" v-bind:class="[scr.best ? 'bold' : '']" track-by="$index")
                | {{  scr.value === null ? 'NA' : parseInt(scr.value * 1000) / 1000 }}
      .score-footer
        | {{{ selectedScoresMeta.desc }}} Scores for the current season are calculated using the most recently
        | updated data. Final values may differ.
</template>

<script>
import { mapActions, mapGetters } from "vuex";
import nprogress from "nprogress";
import tablesort from "tablesort";

const cleanNumber = i => i.replace(/[^\-?0-9.]/g, "");

const compareNumber = (a, b) => {
  a = parseFloat(a);
  b = parseFloat(b);
  a = isNaN(a) ? 0 : a;
  b = isNaN(b) ? 0 : b;
  return a - b;
};

export default {
  computed: {
    ...mapGetters([
      "selectedRegionId",
      "selectedSeasonId",
      "selectedScoresData",
      "selectedScoresMeta"
    ]),
    ...mapGetters("switches", [
      "showTimeChart",
      "showDistributionChart",
      "showScoresPanel",
      "nextScoreActive",
      "prevScoreActive"
    ]),
    ...mapGetters("models", ["modelIds", "modelMeta"]),
    ...mapGetters("scores", ["scoresHeaders"])
  },
  methods: {
    ...mapActions([
      "importLatestChunk",
      "initTimeChart",
      "initDistributionChart",
      "plotTimeChart",
      "plotDistributionChart",
      "clearTimeChart",
      "clearDistributionChart",
      "downloadSeasonData",
      "downloadScoresData",
      "downloadDistData"
    ]),
    ...mapActions("switches", [
      "displayTimeChart",
      "displayDistributionChart",
      "displayScoresPanel",
      "selectNextScore",
      "selectPrevScore"
    ]),
    ...mapActions("weeks", ["readjustSelectedWeek", "resetToFirstIdx"])
  },
  ready() {
    require.ensure(["../../store/data"], () => {
      this.importLatestChunk(require("../../store/data"));

      this.resetToFirstIdx();
      this.displayTimeChart();

      tablesort.extend(
        "number",
        function(item) {
          return true; // Don't care
        },
        function(a, b) {
          a = cleanNumber(a);
          b = cleanNumber(b);
          return compareNumber(b, a);
        }
      );

      tablesort(document.getElementById("score-table"));

      window.loading_screen.finish();
    });
  },
  watch: {
    showTimeChart: function() {
      this.readjustSelectedWeek();
      if (this.showTimeChart) {
        // Check if we need to download chunks
        nprogress.start();
        this.downloadSeasonData({
          http: this.$http,
          id: this.selectedSeasonId,
          success: () => {
            this.initTimeChart("#chart-right");
            this.plotTimeChart();
            nprogress.done();
          },
          fail: err => console.log(err)
        });
      } else {
        this.clearTimeChart();
      }
    },
    showDistributionChart: function() {
      if (this.showDistributionChart) {
        // Check if we need to download chunks
        nprogress.start();
        this.downloadDistData({
          http: this.$http,
          id: `${this.selectedSeasonId}-${this.selectedRegionId}`,
          success: () => {
            this.initDistributionChart("#chart-right");
            this.plotDistributionChart();
            nprogress.done();
          },
          fail: err => console.log(err)
        });
      } else {
        this.clearDistributionChart();
      }
    },
    showScoresPanel: function() {
      if (this.showScoresPanel) {
        // Check if we need to download chunks
        nprogress.start();
        this.downloadScoresData({
          http: this.$http,
          id: this.selectedSeasonId,
          success: () => {
            nprogress.done();
          },
          fail: err => console.log(err)
        });
      }
    }
  }
};
</script>
