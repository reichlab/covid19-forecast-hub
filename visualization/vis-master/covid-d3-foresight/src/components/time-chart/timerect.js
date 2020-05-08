import SComponent from '../s-component'

/**
 * Time rectangle for navigation guidance
 */
export default class TimeRect extends SComponent {
  constructor(layout) {
    super()
    this.rect = this.selection.append('rect')
      .attr('x', 0)
      .attr('y', 0)
      .attr('width', 0)
      .attr('height', layout.height)
      .attr('class', 'timerect')

    this.text = this.selection.append('text')
      .attr('class', 'data-version-text')
      .attr('transform', `translate(15, 0) rotate(-90)`)
      .style('text-anchor', 'end')
    //.text('Data as of')
  }

  plot(scales) {
    this.xScaleDate = scales.xScaleDate
  }

  update(time) {
    if (time === null) {
      // We don't know the data version time
      this.hidden = true
    } else {
      this.hidden = false
      this.rect
        .transition()
        .duration(200)
        .attr('width', this.xScaleDate(time))

      this.text
        .transition()
        .duration(200)
        .attr('transform', `translate(${this.xScaleDate(time) + 15}, 10) rotate(-90)`)
    }
  }
}