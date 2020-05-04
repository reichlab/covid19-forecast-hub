import * as d3 from 'd3'
import SComponent from '../../s-component'
import { applyStyle } from '../../../utilities/style'
import { kebabCase } from '../../../utilities/misc'

export default class LineMarker extends SComponent {
  constructor (id, style) {
    super()
    this.selection
      .attr('class', 'prediction-group')
      .attr('id', kebabCase(id) + '-marker')

    this.selection.append('path')
      .attr('class', 'area-prediction')
      .style('fill', style.color)
    applyStyle(this.selection.select('.area-prediction'), style.area)

    this.selection.append('path')
      .attr('class', 'line-prediction')
      .style('stroke', style.color)
    applyStyle(this.selection.select('.line-prediction'), style.line)

    this.selection.selectAll('.point-prediction')
      .enter()
      .append('circle')
      .attr('class', 'point-prediction')
  }

  move (cfg, series) {
    let circles = this.selection.selectAll('.point-prediction')
        .data(series)

    circles.exit().remove()

    circles.enter().append('circle')
      .merge(circles)
      .attr('class', 'point-prediction')
      .transition()
      .duration(200)
      .ease(d3.easeQuadOut)
      .attr('cx', d => cfg.scales.xScale(d.index))
      .attr('cy', d => cfg.scales.yScale(d.point))
      .attr('r', 3)
      .style('stroke', cfg.style.color)
    applyStyle(circles, cfg.style.point)

    let line = d3.line()
        .x(d => cfg.scales.xScale(d.index))
        .y(d => cfg.scales.yScale(d.point))

    this.selection.select('.line-prediction')
      .datum(series)
      .transition()
      .duration(200)
      .attr('d', line)

    let area = d3.area()
        .x(d => cfg.scales.xScale(d.index))
        .y1(d => cfg.scales.yScale(d.low))
        .y0(d => cfg.scales.yScale(d.high))

    this.selection.select('.area-prediction')
      .datum(series)
      .transition()
      .duration(200)
      .attr('d', area)
  }
}
