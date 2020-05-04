import * as d3 from 'd3'
import SComponent from '../s-component'
import { applyStyle } from '../../utilities/style'

/**
 * Additional line. Other components actually can inherit from this after a while.
 * Will also factor this properly.
 */
export default class AdditionalLine extends SComponent {
  constructor (layout, { id, meta, style, legend, tooltip }) {
    super()
    this.selection.attr('class', 'additional-group')

    this.line = this.selection.append('line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', layout.width)
      .attr('y2', 0)
      .style('stroke', style.color)
      .style('fill', 'transparent')

    applyStyle(this.line, style.line)

    this.path = this.selection.append('path')
      .style('stroke', style.color)
      .style('fill', 'transparent')

    applyStyle(this.path, style.line)

    this.id = id
    this.meta = meta
    this.style = style
    this.legend = legend
    this.tooltip = tooltip

    this.dataType = 'array' // 'array' or 'scalar'
  }

  plotScalar (scales, value) {
    this.line
      .transition()
      .duration(200)
      .attr('y1', scales.yScale(value))
      .attr('y2', scales.yScale(value))
    this.data = value
  }

  plotArray (scales, array) {
    // Save data for queries
    this.data = array.map((val, idx) => {
      return {
        x: idx,
        y: val
      }
    })

    let path = d3.line()
        .x(d => scales.xScale(d.x))
        .y(d => scales.yScale(d.y))

    this.path
      .datum(this.data.filter(d => d.y))
      .transition()
      .duration(200)
      .attr('d', path)

    let r
    try {
      r = this.style.point.r
    } catch (e) {
      r = 2
    }

    // Only plot non nulls
    let circles = this.selection.selectAll('.point-additional')
        .data(this.data.filter(d => d.y))

    circles.exit().remove()

    circles.enter().append('circle')
      .merge(circles)
      .attr('class', 'point-additional')
      .transition(200)
      .ease(d3.easeQuadOut)
      .attr('cx', d => scales.xScale(d.x))
      .attr('cy', d => scales.yScale(d.y))
      .attr('r', r)
      .style('stroke', this.style.color)
      .style('fill', this.style.color)

    applyStyle(circles, this.style.point)
  }

  plot (scales, data) {
    if (typeof data === 'number') {
      this.dataType = 'scalar'
      this.path.attr('display', 'none')
      this.line.attr('display', null)
      this.plotScalar(scales, data)
    } else {
      this.dataType = 'array'
      this.line.attr('display', 'none')
      this.path.attr('display', null)
      this.plotArray(scales, data)
    }
  }

  query (idx) {
    if (this.hidden) {
      return false
    } else {
      try {
        if (this.dataType === 'scalar') {
          return this.data
        } else {
          return this.data[idx].y
        }
      } catch (e) {
        return false
      }
    }
  }
}
