import * as d3 from 'd3'
import * as tt from '../utilities/tooltip'

/**
 * Generic class for a component
 */
export default class Component {
  constructor (elem = document.createElement('div')) {
    this.selection = d3.select(elem)
  }

  /**
   * Return HTML node for d3.append
   */
  get node () {
    return this.selection.node()
  }

  /**
   * General css display based hidden prop
   */
  get hidden () {
    return this.selection.style('display') === 'none'
  }

  set hidden (state) {
    this.selection.style('display', state ? 'none' : null)
  }

  /**
   * Add an on hover tooltip
   */
  addTooltip (tooltip, html, direction = 'right') {
    this.selection
      .on('mouseover', () => { tooltip.hidden = false })
      .on('mouseout', () => { tooltip.hidden = true })
      .on('mousemove', function () {
        tooltip.render(html)
        tt.moveTooltip(tooltip, d3.select(this), direction)
      })
  }

  /**
   * Make pointer cursor. Rest is handled by subclasses.
   */
  addOnClick () {
    this.selection.style('cursor', 'pointer')
  }

  /**
   * Append another component to this
   */
  append (component) {
    this.selection.append(() => component.node)
    return component
  }
}
