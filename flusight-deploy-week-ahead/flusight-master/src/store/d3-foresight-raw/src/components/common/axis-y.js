import * as d3 from 'd3'
import * as tt from '../../utilities/tooltip'
import SComponent from '../s-component'
import { selectUncle } from '../../utilities/misc'

/**
 * Simple linear Y axis with informative label
 */
export class YAxis extends SComponent {
  constructor (layout, { tooltip, title, description, url }) {
    super()
    this.selection.attr('class', 'axis axis-y')

    let yText = this.selection.append('text')
        .attr('transform', `translate(-45 , ${layout.height / 2}) rotate(-90)`)
        .attr('dy', '.71em')
        .style('text-anchor', 'middle')
        .text(title)
        .on('mouseover', () => { tooltip.hidden = false })
        .on('mouseout', () => { tooltip.hidden = true })
        .on('mousemove', function () {
          tooltip.render(tt.parseText({ text: description }))
          tt.moveTooltip(tooltip, selectUncle(this, '.overlay'))
        })

    if (url) {
      yText
        .style('cursor', 'pointer')
        .on('click', () => {
          window.open(url, '_blank')
        })
    }
  }

  plot (scales, maxTicks) {
    let yAxis = d3.axisLeft(scales.yScale).tickFormat(d3.format('.2f'))
    if (maxTicks) yAxis.ticks(maxTicks)
    this.selection
      .transition().duration(200).call(yAxis)
  }
}
