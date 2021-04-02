<style lang="scss">
.datamaps-subunit {
  cursor: pointer;
}

#choropleth {
  text-align: center;

  #relative-button-title {
    padding-top: 30px;
    text-align: left;
    font-size: 12px;

    a {
      color: #4a4a4a;
    }
  }

  #relative-button {
    position: absolute;
    text-align: left;
    font-size: 11px;
    cursor: pointer;
    user-select: none;
    .icon {
      margin: 0px 10px;
    }
    span {
      vertical-align: middle;
      &.disabled {
        color: #aaa;
      }
    }
  }
}

.colorbar-group .axis {
  line,
  path {
    fill: none;
    stroke: #bbb !important;
  }
}

#selectors {
  .level {
    margin-bottom: 0px;
  }
}

#switch-tooltip,
#wili-tooltip {
  padding: 5px 10px;
  ul {
    list-style: disc inside none;
    display: table;

    li {
      display: table-row;
      &::before {
        content: "•";
        display: table-cell;
        text-align: right;
        padding-right: 10px;
      }
    }
  }
}

#choropleth-tooltip {
  padding: 5px 10px;
  .value {
    font-size: 12px;
    font-weight: bold;
  }
}
</style>

<template lang="pug">
div
  // Tooltip over relative toggle switch
  #switch-tooltip.tooltip(
    v-show="tooltips.switch.show"
    v-bind:style="tooltips.switch.pos"
  )
    | {{{ tooltips.switch.text }}} 

  // Tooltip over wili text
  #wili-tooltip.tooltip(
    v-show="tooltips.wili.show"
    v-bind:style="tooltips.wili.pos"
  )
    | {{{ tooltips.wili.text }}}

  // Tooltip for map hover
  #choropleth-tooltip.tooltip
    .value
    .region

  #selectors
    .level.is-mobile
      .level-left
        .level-item
          .heading Week <b>{{ selectedWeekName }}</b>
          span#region-selector.select
              select(v-model="currentRegion")
                option(v-for="region in regions") {{ region }}

      .level-right
        .level-item
          p.heading Target
          p.control.title
            span#season-selector.select
              select(v-model="currentSeason")
                option(v-for="season in seasons") {{ season }}

  // Main plotting div
  #choropleth
    #relative-button-title
      a(
      href="https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv" target="_blank"
      v-on:mouseover="showWiliTooltip"
      v-on:mouseout="hideWiliTooltip"
      v-on:mousemove="moveWiliTooltip"
    ) {{ selectedSeasonId }} (Observed)
    #relative-button(
      v-on:click="toggleRelative"
      v-on:mouseover="showSwitchTooltip"
      v-on:mouseout="hideSwitchTooltip"
      v-on:mousemove="moveSwitchTooltip"
    )
      //- span(v-bind:class="[choroplethRelative ? 'disabled' : '']") Absolute
      //- span.icon
      //-   i(
      //-     v-bind:class=`[choroplethRelative ? '' : 'fa-rotate-180',
      //-                   'fa fa-toggle-on']`
      //-    )
      //- span(v-bind:class="[choroplethRelative ? '' : 'disabled']") Relative
</template>

<script>
import Choropleth from "../../choropleth";
import { mapGetters, mapActions } from "vuex";
import nprogress from "nprogress";

export default {
  computed: {
    ...mapGetters([
      "seasons",
      "regions",
      "selectedRegionId",
      "selectedSeasonId",
      "metadata"
    ]),
    ...mapGetters("switches", [
      "selectedSeason",
      "selectedRegion",
      "choroplethRelative",
      "showTimeChart",
      "showScoresPanel",
      "showDistributionChart"
    ]),
    ...mapGetters("weeks", ["selectedWeekName"]),
    currentSeason: {
      get() {
        return this.seasons[this.selectedSeason];
      },
      set(val) {
        // Check if we need to download the season
        nprogress.start();

        let setSeason = () => {
          this.updateSelectedSeason(this.seasons.indexOf(val));
          nprogress.done();
        };

        this.downloadSeasonData({
          http: this.$http,
          id: val,
          success: () => {
            if (this.showDistributionChart) {
              // Check if we need to download dist data
              this.downloadDistData({
                http: this.$http,
                id: `${val}-${this.selectedRegionId}`,
                success: setSeason,
                fail: err => console.log(err)
              });
            } else if (this.showScoresPanel) {
              // Check if we need to download scores data
              this.downloadScoresData({
                http: this.$http,
                id: val,
                success: setSeason,
                fail: err => console.log(err)
              });
            } else {
              setSeason();
            }
          },
          fail: err => console.log(err)
        });
      }
    },
    currentRegion: {
      get() {
        return this.regions[this.selectedRegion];
      },
      set(val) {
        let regionIdx = this.regions.indexOf(val);
        let regionId = this.metadata.regionData[regionIdx].id;
        let distId = `${this.selectedSeasonId}-${regionId}`;
        if (this.showDistributionChart) {
          // If on distribution chart, check and request for dist data
          nprogress.start();
          this.downloadDistData({
            http: this.$http,
            id: distId,
            success: () => {
              this.updateSelectedRegion(regionIdx);
              nprogress.done();
            },
            fail: err => console.log(err)
          });
        } else {
          this.updateSelectedRegion(regionIdx);
        }
      }
    }
  },
  methods: {
    ...mapActions([
      "importLatestChunk",
      "initChoropleth",
      "plotChoropleth",
      "updateChoropleth",
      "downloadSeasonData",
      "downloadScoresData",
      "downloadDistData"
    ]),
    ...mapActions("switches", [
      "updateSelectedRegion",
      "updateSelectedSeason",
      "toggleRelative"
    ]),
    showSwitchTooltip() {
      this.tooltips.switch.show = true;
    },
    hideSwitchTooltip() {
      this.tooltips.switch.show = false;
    },
    moveSwitchTooltip(event) {
      let obj = this.tooltips.switch;

      obj.pos.top = event.clientY + 15 + "px";
      obj.pos.left = event.clientX + 15 + "px";
    },
    showWiliTooltip() {
      this.tooltips.wili.show = true;
    },
    hideWiliTooltip() {
      this.tooltips.wili.show = false;
    },
    moveWiliTooltip(event) {
      let obj = this.tooltips.wili;

      obj.pos.top = event.clientY + 15 + "px";
      obj.pos.left = event.clientX + 15 + "px";
    }
  },
  data() {
    return {
      tooltips: {
        switch: {
          show: false,
          text: `Choose between
                 <ul>
                 <li><b>Absolute</b> Cumulative Death Values or</li>
                 <li><b>Relative</b> values as the percent above/below the regional CDC baseline</li>
                 </ul>`,
          pos: {
            top: "0px",
            left: "0px"
          }
        },
        wili: {
          show: false,
          text: `Cumulative deaths deaths due to COVID-19 in the United States<br><br>
                 <em>Click to know more</em>`,
          pos: {
            top: "0px",
            left: "0px"
          }
        }
      }
    };
  },
  ready() {
    require.ensure(["../../store/data"], () => {
      this.importLatestChunk(require("../../store/data"));

      // first loaded season is Incident Deaths 
      // remember: selected season data must be manually loaded
      //           otherwise visualization will spin!
      this.updateSelectedSeason(0);

      // Setup map
      this.initChoropleth(
        new Choropleth("choropleth", regionIdx => {
          if (this.showDistributionChart) {
            // If on distribution chart, check and request for dist data
            let regionId = this.metadata.regionData[regionIdx].id;
            let distId = `${this.selectedSeasonId}-${regionId}`;
            nprogress.start();
            this.downloadDistData({
              http: this.$http,
              id: distId,
              success: () => {
                this.updateSelectedRegion(regionIdx);
                nprogress.done();
              },
              fail: err => console.log(err)
            });
          } else {
            this.updateSelectedRegion(regionIdx);
          }
        })
      );

      // Setup data
      this.plotChoropleth();

      // Hot start
      this.updateChoropleth();
    });
  }
};
</script>
