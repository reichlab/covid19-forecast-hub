import SComponent from '../s-component'

export default class TimezeroLine extends SComponent {
  constructor (layout) {
    super()
    this.line = this.selection.append('line')
      .attr('class', 'timezero-line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', layout.totalHeight)

    this.text = this.selection.append('text')
      .attr('class', 'timezero-text')
      .attr('transform', 'translate(-10, 10) rotate(-90)')
      .style('text-anchor', 'end')
      .text('Timezero')
  }

  set x (x) {
    this.line
      .transition()
      .duration(200)
      .attr('x1', x)
      .attr('x2', x)

    this.text
      .transition()
      .duration(200)
      .attr('dy', x)
  }

  set textHidden (state) {
    this.text.style('display', state ? 'none' : null)
  }

  plot (scales) {
    this.xScale = scales.xScale
  }

  update (idx) {
    this.x = this.xScale(idx)
  }
}
