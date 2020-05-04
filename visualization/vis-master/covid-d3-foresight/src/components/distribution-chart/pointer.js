import * as d3 from 'd3'
import SComponent from '../s-component'
import * as ev from '../../events'

/**
 * Return triangle points for drawing polyline centered at origin
 */
const generateTrianglePoints = origin => {
  let side = 15
  return [
    [origin[0] - side / 2, origin[1] - side / Math.sqrt(2)],
    [origin[0] + side / 2, origin[1] - side / Math.sqrt(2)],
    [origin[0], origin[1] - 2]
  ].map(p => p[0] + ',' + p[1]).join(' ')
}

/**
 * Pointer over current position in time axis
 */
export default class Pointer extends SComponent {
  constructor (layout, { uuid }) {
    super()
    this.selection.attr('class', 'time-pointer-group')

    // Save fixed y position
    this.yPos = layout.height

    this.selection.append('polyline')
      .attr('class', 'pointer-triangle')
      .attr('points', generateTrianglePoints([0, this.yPos]))

    // Add overlay over axis to allow clicks
    this.selection.append('rect')
      .attr('class', 'pointer-overlay')
      .attr('height', 80)
      .attr('width', layout.width)
      .attr('x', 0)
      .attr('y', layout.height - 30)

    this.uuid = uuid
  }

  plot (scales, currentIdx) {
    let uuid = this.uuid
    this.selection.select('.pointer-triangle')
      .transition()
      .duration(200)
      .attr('points', generateTrianglePoints([scales.xScale(currentIdx), this.yPos]))

    this.selection.select('.pointer-overlay').on('click', function () {
      let clickIndex = Math.round(scales.xScale.invert(d3.mouse(this)[0]))
      ev.publish(uuid, ev.JUMP_TO_INDEX, clickIndex)
    })
  }
}
