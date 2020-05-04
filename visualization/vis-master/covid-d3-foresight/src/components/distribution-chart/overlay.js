import * as d3 from 'd3'
import * as tt from '../../utilities/tooltip'
import SComponent from '../s-component'

export default class Overlay extends SComponent {
  constructor (layout, { tooltip }) {
    super()

    // Add mouse hover line
    this.line = this.selection.append('line')
      .attr('class', 'hover-line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', layout.height)
      .style('display', 'none')

    this.overlay = this.selection.append('rect')
      .attr('class', 'overlay')
      .attr('height', layout.height)
      .attr('width', layout.width)
      .on('mouseover', () => {
        this.line.style('display', null)
        tooltip.hidden = false
      })
      .on('mouseout', () => {
        this.line.style('display', 'none')
        tooltip.hidden = true
      })
    this.tooltip = tooltip
  }

  plot (scales, predictions) {
    let line = this.line
    let tooltip = this.tooltip
    this.overlay
      .on('mousemove', function () {
        let mouse = d3.mouse(this)
        // Snap x to nearest tick
        let index = Math.round(mouse[0] / scales.xScale.range()[1] * scales.xScale.domain().length)
        let snappedX = scales.xScale(scales.xScale.domain()[index])

        // Move the cursor
        line
          .transition()
          .duration(50)
          .attr('x1', snappedX)
          .attr('x2', snappedX)

        // Format bin value to display
        let binVal = tt.formatBin(scales.xScale.domain(), index)

        tooltip.render(tt.parsePredictions({
          title: `Bin: ${binVal}`,
          predictions: predictions,
          index
        }))

        // Tooltip position
        tt.moveTooltip(tooltip, d3.select(this))
      })
  }
}
