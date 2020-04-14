import * as d3 from 'd3'
import SComponent from '../../s-component'

export default class LineMarker extends SComponent {
  constructor (id, color) {
    super()
    this.selection
      .attr('class', 'prediction-group')
      .attr('id', id + 'marker')

    this.selection.append('path')
      .attr('class', 'area-prediction')
      .style('fill', color)

    this.selection.append('path')
      .attr('class', 'line-prediction')
      .style('stroke', color)

    this.selection.selectAll('.point-prediction')
      .enter()
      .append('circle')
      .attr('class', 'point-prediction')
      .style('stroke', color)
  }

  move (cfg, series, anchorPoint) {
    let circles = this.selection.selectAll('.point-prediction')
        .data(series.slice(anchorPoint !== null ? 1 : 0))

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
      .style('stroke', cfg.color)

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
