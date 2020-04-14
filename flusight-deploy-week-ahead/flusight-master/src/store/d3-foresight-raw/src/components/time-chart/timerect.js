import SComponent from '../s-component'

/**
 * Time rectangle for navigation guidance
 */
export default class TimeRect extends SComponent {
  constructor (layout) {
    super()
    this.rect = this.selection.append('rect')
      .attr('x', 0)
      .attr('y', 0)
      .attr('width', 0)
      .attr('height', layout.height)
      .attr('class', 'timerect')
  }

  plot (scales) {
    this.xScale = scales.xScale
  }

  update (idx) {
    this.rect
      .transition()
      .duration(200)
      .attr('width', this.xScale(idx))
  }
}
