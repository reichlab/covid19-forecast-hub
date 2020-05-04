import * as d3 from 'd3'
import * as tt from '../../utilities/tooltip'
import { selectUncle } from '../../utilities/misc'
import SComponent from '../s-component'

/**
 * Historical lines
 */
export default class HistoricalLines extends SComponent {
  constructor ({ tooltip }) {
    super()
    this.selection.attr('class', 'history-group')
    this.tooltip = tooltip
    this.id = 'History'
  }

  plot (scales, historicalData) {
    this.clear()

    let line = d3.line()
        .x(d => scales.xScale(d.x))
        .y(d => scales.yScale(d.y))

    historicalData.map(hd => {
      let plottingData = hd.actual.map((data, idx) => {
        return {
          x: idx,
          y: data
        }
      })

      let path = this.selection.append('path')
          .attr('class', 'line-history')
          .attr('id', hd.id + '-history')

      path.datum(plottingData)
        .transition()
        .duration(200)
        .attr('d', line)

      let tooltip = this.tooltip
      path.on('mouseover', function () {
        d3.select('.line-history.highlight')
          .datum(plottingData)
          .attr('d', line)
        tooltip.hidden = false
      }).on('mouseout', function () {
        d3.select('.line-history.highlight')
          .datum([])
          .attr('d', line)
        tooltip.hidden = true
      }).on('mousemove', function (event) {
        tooltip.render(tt.parseText({ text: hd.id }))
        tt.moveTooltip(tooltip, selectUncle(this, '.overlay'))
      })
    })

    // Add highlight overlay
    this.selection.append('path')
      .attr('class', 'line-history highlight')
  }
}
