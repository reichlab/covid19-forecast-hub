import * as d3 from 'd3'
import * as tt from '../../utilities/tooltip'
import SComponent from '../s-component'
import {
  selectUncle
} from '../../utilities/misc'

/**
 * Simple linear Y axis with informative label
 */
export class YAxis extends SComponent {
  constructor(layout, {
    tooltip,
    title,
    description,
    url
  }) {
    super()

    this.title = title;
    this.layout = layout;
    this.tooltip = tooltip;
    this.description = description;

    this.selection.attr('class', 'axis axis-y')

    this.yText = this.selection.append('text')
      .attr('id', 'y-axis-label')
      .attr('transform', `translate(-54 , ${layout.height / 2}) rotate(-90)`)
      .attr('dy', '.71em')
      .style('text-anchor', 'middle')
      .text(this.title)
      .on('mouseover', () => {
        tooltip.hidden = false
      })
      .on('mouseout', () => {
        tooltip.hidden = true
      })
      .on('mousemove', function () {
        tooltip.render(tt.parseText({
          text: description
        }))
        tt.moveTooltip(tooltip, selectUncle(this, '.overlay'))
      });
  }

  changeTitle(titleChange) {
    this.title = titleChange
    this.selection.selectAll('#y-axis-label').remove()
    this.selection.append('text')
      .attr('id', 'y-axis-label')
      .attr('transform', `translate(-54 , ${this.layout.height / 2}) rotate(-90)`)
      .attr('dy', '.71em')
      .style('text-anchor', 'middle')
      .text(this.title)
      .on('mouseover', () => {
        this.tooltip.hidden = false
      })
      .on('mouseout', () => {
        this.tooltip.hidden = true
      })
      .on('mousemove', function () {
        this.tooltip.render(tt.parseText({
          text: this.description
        }))
        tt.moveTooltip(this.tooltip, selectUncle(this, '.overlay'))
      })
  }

  plot(scales, maxTicks) {
    let yAxis = d3.axisLeft(scales.yScale).tickFormat(d3.format(','))
    if (maxTicks) yAxis.ticks(maxTicks)
    this.selection
      .transition().duration(200).call(yAxis)
  }
}