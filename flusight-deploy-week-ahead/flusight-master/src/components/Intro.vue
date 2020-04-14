<style lang="scss" scoped>

#intro-tooltip {
  z-index: 900;
  position: fixed;
  top: 0px;
  left: 0px;
  background-color: white;
  padding: 15px 20px;
  box-shadow: 0px 0px 5px;
  border-radius: 2px;
  color: #333;
  font-size: 11px;
  width: 300px;
  #intro-title {
    font-size: 20px;
    font-weight: bold;
    margin-bottom: 10px;
  }
  #intro-content {
    font-size: 13px;
    margin-bottom: 20px;
  }
  .right {
    float: right;
  }
  #intro-buttons a {
    margin: 0px 2px;
  }
}

#intro-overlay {
  position: fixed;
  top: 0px;
  bottom: 0px;
  left: 0px;
  right: 0px;
  background-color: rgba(0, 0, 0, 0.3);
  z-index: 800;
}

</style>

<template lang="pug">
div
  // Dark overlay during demo
  #intro-overlay(v-on:click="moveIntroFinish" v-show="introShow")

  #intro-tooltip(v-show="introShow")
    #intro-title {{ currentIntro.title }}
    #intro-content(v-html="currentIntro.content")
    #intro-buttons

      // Close intro button
      a.button.is-small(v-on:click="moveIntroFinish")
        span.icon.is-small
          i.fa.fa-times
        span Finish

      span.right
        // Movement buttons
        a(
          v-bind:class=`[introAtFirst ? 'is-disabled' : '',
                        'button is-info is-small is-outlined']`
          v-on:click="moveIntroBackward"
         )
          span.icon.is-small
            i.fa.fa-angle-left
          span Previous

        a(
          v-bind:class=`[introAtLast ? 'is-disabled' : '',
                        'button is-info is-small']`
          v-on:click="moveIntroForward"
         )
          span.icon.is-small
            i.fa.fa-angle-right
          span Next
</template>

<script>
import * as d3 from 'd3'
import { mapActions, mapGetters } from 'vuex'
import * as cookie from 'js-cookie'

export default {
  computed: {
    ...mapGetters('intro', [
      'currentIntro',
      'introAtFirst',
      'introAtLast',
      'introShow',
      'introStep'
    ]),
    ...mapGetters(['branding'])
  },
  methods: {
    ...mapActions('intro', [
      'appendIntroItems',
      'moveIntroForward',
      'moveIntroBackward',
      'moveIntroFinish',
      'moveIntroStart'
    ]),
    ...mapActions('switches', [
      'displayTimeChart',
      'displayDistributionChart',
      'displayScoresPanel'
    ]),
    demoStep (data) {
      let tooltip = d3.select('#intro-tooltip')
      let tooltipBB = tooltip.node().getBoundingClientRect()

      if (data.element === '') {
        let xPos = (window.innerWidth - tooltipBB.width) / 2
        let yPos = (window.innerHeight - tooltipBB.height) / 2

        tooltip.transition()
          .duration(200)
          .style('top', yPos + 'px')
          .style('left', xPos + 'px')
      } else {
        let target = d3.select(data.element)
        let targetBB = target.node().getBoundingClientRect()

        // Highlight current div
        target.style('background-color', 'white')
        target.style('z-index', '850')

        let yPos = targetBB.top

        if (data.direction === 'left') {
          tooltip.transition()
            .duration(200)
            .style('top', yPos + 'px')
            .style('left', (targetBB.left - tooltipBB.width - 20) + 'px')
        } else {
          tooltip.transition()
            .duration(200)
            .style('top', yPos + 'px')
            .style('left', (targetBB.left + targetBB.width + 20) + 'px')
        }
      }

      // Execute intro hook
      if (data.hook) data.hook()
    },
    setLastElement (el) {
      this.lastElement = el
    }
  },
  ready () {
    // Append intro items
    this.appendIntroItems([
      {
        title: 'Season',
        content: `Use this pull-down menu to select the flu season`,
        direction: 'right',
        element: '#season-selector'
      },
      {
        title: 'Region',
        content: `Use this drop down to select the region to show predictions
                  for.`,
        direction: 'right',
        element: '#region-selector'
      },
      {
        title: 'Predictions',
        content: `<p>You can use your keyboard's arrow keys or mouse to move
                  between weeks for which we have data and predictions.</p>
                  <br><p>The "current week" is the leading edge of the grey
                  shaded region: the predictions shown were made when that
                  week's data became available.</p><br><p>A forecast for the
                  next four weeks is shown, as is the time and height of the
                  peak week and the time of season onset.</p>`,
        direction: 'left',
        element: '#chart-container',
        hook: this.displayTimeChart
      },
      {
        title: 'Probabilities',
        content: `The probability distributions underlying these predictions
                  targets can be seen by switching to the <em>Distribution
                  Chart</em> tab here`,
        direction: 'left',
        element: '#chart-container',
        hook: this.displayDistributionChart
      },
      {
        title: 'Scores',
        content: `Performance of the models on currently selected season and
                  region can be seen in the tab <em>Scores</em> tab`,
        direction: 'left',
        element: '#chart-container',
        hook: this.displayScoresPanel
      },
      {
        title: 'US Map',
        content: `<p>The map shows data for the currently selected week.</p>
                  <p>You can also click on the map to see predictions for a
                  particular region.</p>`,
        direction: 'right',
        element: '#map-intro',
        hook: this.displayTimeChart
      },
      {
        title: 'Legend',
        content: `You can interact with the legend to display different
                  combinations of models, or to toggle the historical data
                  lines and change confidence interval. Click on the links
                  next to the models for more information about the models
                  themselves.`,
        direction: 'left',
        element: '.d3f-controls .legend-drawer'
      },
      {
        title: 'Other controls',
        content: `You can use these buttons to hide the legend
                  or move the graph forward or backward in time.`,
        direction: 'left',
        element: '.d3f-controls .control-btns'
      },
      {
        title: 'Finished',
        content: `Check out the source for this app and provide feedback on
                  the project's github page <a href="` +
                  this.branding.sourceUrl + `" target="_blank">here</a>.`,
        direction: 'left',
        element: ''
      }
    ])

    this.demoStep(this.currentIntro)
    this.moveIntroFinish()

    // Check for first run
    // Trigger intro
    if (cookie.get('firstRun') !== 'true') {
      cookie.set('firstRun', 'true', { expires: 365 })
      this.moveIntroStart()
    }

    // Exit on escape
    window.addEventListener('keyup', evt => {
      if (evt.which === 27 || evt.keyCode === 27) {
        this.moveIntroFinish()
      }
    })
  },
  data () {
    return {
      lastElement: ''
    }
  },
  watch: {
    introStep: function () {
      // Un-highlight previous div
      if (this.lastElement !== '') {
        d3.select(this.lastElement)
          .style('z-index', null)
      }
      this.demoStep(this.currentIntro)

      // Save current as last element
      this.setLastElement(this.currentIntro.element)
    }
  }
}
</script>
