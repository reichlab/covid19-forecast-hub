import Component from '../component'

/**
 * Tooltip
 */
export default class Tooltip extends Component {
  constructor () {
    super()

    this.selection
      .attr('class', `d3f-tooltip`)
      .style('display', 'none')

    this.offset = 15
  }

  get width () {
    return this.node.getBoundingClientRect().width
  }

  move (position, direction = 'right') {
    this.selection
      .style('top', (position.y + this.offset) + 'px')
      .style('left', (position.x + (direction === 'right' ? this.offset : -this.width - this.offset)) + 'px')
  }

  render (html) {
    if (html === '') {
      this.hidden = true
    } else {
      this.hidden = false
      this.selection.html(html)
    }
  }
}
