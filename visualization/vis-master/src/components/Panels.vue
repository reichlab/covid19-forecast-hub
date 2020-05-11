<style lang="scss" scoped>
h1 a {
  color: black;
}
.columns {
  .column {
    position: relative;
  }
}
#choropleth-container,
#chart-container {
  background: white;
}
#chart-container.column.is-8 {
  margin-top: -4px;
  margin-bottom: 0;
  padding-bottom: 0;
  padding-top: 0;
}
</style>

<template lang="pug">
.columns
  #map-intro.column.is-4
    // Title
    h1.title
      a(v-bind:href="branding.parentUrl") COVID-19 Forecasts
    h2.subtitle
      | Week Ahead
    hr
    #choropleth-container
      choropleth
  #chart-container.column.is-8
    charts-panel    
</template>

<script>
import Choropleth from "./Panels/Choropleth";
import ChartsPanel from "./Panels/ChartsPanel";
import { mapGetters, mapActions } from "vuex";
export default {
  components: {
    Choropleth,
    ChartsPanel
  },
  computed: {
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters(["branding"]),
    ...mapGetters("switches", [
      "selectedRegion",
      "selectedSeason",
      "choroplethRelative"
    ]),
    ...mapGetters("weeks", ["selectedWeekIdx"])
  },
  methods: {
    ...mapActions([
      "updateTimeChart",
      "updateChoropleth",
      "plotChoropleth",
      "plotTimeChart",
      "plotDistributionChart"
    ]),
    ...mapActions("weeks", ["readjustSelectedWeek"])
  },
  watch: {
    selectedRegion: function() {
      // Jiggle weeks
      this.readjustSelectedWeek();
      this.plotTimeChart();
      this.plotDistributionChart();
      this.updateChoropleth();
    },
    selectedSeason: function() {
      // Jiggle weeks
      this.readjustSelectedWeek();
      this.plotTimeChart();
      this.plotChoropleth();
      this.plotDistributionChart();
    },
    choroplethRelative: function() {
      this.plotChoropleth();
    },
    selectedWeekIdx: function() {
      this.updateChoropleth();
      this.updateTimeChart();
      this.plotDistributionChart();
    }
  }
};
</script>
