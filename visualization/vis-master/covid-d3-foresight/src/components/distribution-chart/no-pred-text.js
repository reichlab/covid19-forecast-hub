import SComponent from '../s-component'

export default class NoPredText extends SComponent {
  constructor () {
    super()
    this.text = this.selection.append('text')
      .attr('class', 'no-pred-text')
      .attr('transform', `translate(30 , 30)`)

    this.text.append('tspan')
      .text('Predictions not available')
      .attr('x', 0)

    this.text.append('tspan')
      .text('for selected time')
      .attr('x', 0)
      .attr('dy', '2em')
  }
}
