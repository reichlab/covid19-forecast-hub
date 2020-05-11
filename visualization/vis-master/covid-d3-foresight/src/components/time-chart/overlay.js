import * as d3 from 'd3'
import * as tt from '../../utilities/tooltip'
import * as ev from '../../events'
import SComponent from '../s-component'
import AdditionLine from '../time-chart/additional-line'
import Prediction from '../time-chart/prediction'

class NoPredText extends SComponent {
  constructor () {
    super()
    this.selection.append('text')
      .attr('class', 'no-pred-text')
      .attr('transform', 'translate(20, 20)')
      .text('Predictions not available')

    this.selection.append('text')
      .attr('class', 'no-pred-text')
      .attr('transform', 'translate(20, 40)')
      .text('for selected time')
  }
}

class HoverLine extends SComponent {
  constructor (layout) {
    super()
    this.line = this.selection.append('line')
      .attr('class', 'hover-line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', layout.totalHeight)
  }

  set x (x) {
    this.line
      .transition()
      .duration(50)
      .attr('x1', x)
      .attr('x2', x)
  }
}

class TodayLine extends SComponent {
  constructor (layout) {
    super()
    this.line = this.selection.append('line')
      .attr('class', 'now-line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', layout.totalHeight)

    this.text = this.selection.append('text')
      .attr('class', 'now-text')
      .attr('transform', 'translate(15, 10) rotate(-90)')
      .style('text-anchor', 'end')
      .text('Today')
  }

  set x (x) {
    this.line
      .attr('x1', x)
      .attr('x2', x)

    this.text
      .attr('dy', x)
  }
}

export default class Overlay extends SComponent {
  constructor (layout, { tooltip, uuid }) {
    super()

    this.noPredText = this.append(new NoPredText(layout))
    this.todayLine = this.append(new TodayLine(layout))
    this.hoverLine = this.append(new HoverLine(layout))
    this.hoverLine.hidden = true

    this.overlay = this.selection.append('rect')
      .attr('class', 'overlay')
      .attr('height', layout.totalHeight)
      .attr('width', layout.width)
      .on('mouseover', () => {
        this.hoverLine.hidden = false
        tooltip.hidden = false
      })
      .on('mouseout', () => {
        this.hoverLine.hidden = true
        tooltip.hidden = true
      })

    this.tooltip = tooltip
    this.uuid = uuid
  }

  plot (scales, queryObjects) {
    // Check if `today` lies within the plotting range
    let todayX = scales.xScaleDate(new Date())
    if ((todayX >= scales.xScalePoint(scales.ticks[0])) &&
        (todayX <= scales.xScalePoint(scales.ticks[scales.ticks.length - 1]))) {
      this.todayLine.x = todayX
      this.todayLine.hidden = false
    } else {
      this.todayLine.hidden = true
    }

    let objects = {
      static: queryObjects.filter(q => ['Actual', 'Observed'].indexOf(q.id) > -1),
      models: queryObjects.filter(q => q instanceof Prediction),
      additional: queryObjects.filter(q => {
        return q instanceof AdditionLine && q.tooltip
      })
    }

    // Add mouse move and click events
    let that = this
    this.overlay
      .on('mousemove', function () {
        let mouse = d3.mouse(this)
        // Snap x to nearest tick
        let index = Math.round(scales.xScale.invert(mouse[0]))
        let snappedX = scales.xScale(index)

        that.hoverLine.x = snappedX

        let visibleModels = objects.models.filter(q => {
          // Take only model predictions which have data at index
          return q.query(index) !== false
        })

        let ttTitle = ''
        if (visibleModels.length > 0) {
          // Add note regarding which prediction is getting displayed
          let aheadIndex = visibleModels[0].displayedIdx(index)
          if (aheadIndex !== null) {
            ttTitle = `${aheadIndex + 1} ahead`
          }
        }

        that.tooltip.render(tt.parsePredictions({
          title: ttTitle,
          predictions: [...objects.static, ...objects.additional, ...objects.models],
          index
        }))

        tt.moveTooltip(that.tooltip, d3.select(this))
      })
      .on('click', function () {
        ev.publish(that.uuid, ev.JUMP_TO_INDEX_INTERNAL, Math.round(scales.xScale.invert(d3.mouse(this)[0])))
      })
  }

  update (predictions) {
    this.noPredText.hidden = !predictions.every(p => p.noData)
  }
}
