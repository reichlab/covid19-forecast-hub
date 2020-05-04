import * as d3 from 'd3'
import SComponent from '../s-component'

/**
 * Actual line
 */
export default class Actual extends SComponent {
  constructor () {
    super()
    this.selection.attr('class', 'actual-group')
    this.line = this.selection.append('path')
      .attr('class', 'line-actual')
    this.id = 'Actual'
  }

  plot (scales, actualData) {
    let line = d3.line()
        .x(d => scales.xScale(d.x))
        .y(d => scales.yScale(d.y))

    // Save data for queries
    this.data = actualData.map((data, idx) => {
      return {
        x: idx,
        y: data
      }
    })

    this.line
      .datum(this.data.filter(d => d.y))
      .transition()
      .duration(200)
      .attr('d', line)

    // Only plot non nulls
    let circles = this.selection.selectAll('.point-actual')
        .data(this.data.filter(d => d.y))

    circles.exit().remove()

    circles.enter().append('circle')
      .merge(circles)
      .attr('class', 'point-actual')
      .transition(200)
      .ease(d3.easeQuadOut)
      .attr('cx', d => scales.xScale(d.x))
      .attr('cy', d => scales.yScale(d.y))
      .attr('r', 2)
  }

  query (idx) {
    if (this.hidden) {
      return false
    } else {
      try {
        return this.data[idx].y
      } catch (e) {
        return false
      }
    }
  }
}
