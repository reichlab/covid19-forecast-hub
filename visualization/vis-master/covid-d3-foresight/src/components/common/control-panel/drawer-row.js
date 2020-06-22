/**
 * Row class in control panel
 */

/**
 * Doc guard
 */
import * as d3 from 'd3'
import * as tt from '../../../utilities/tooltip'
import Component from '../../component'

/**
 * An item in the legend drawer.
 */
export default class DrawerRow extends Component {
  constructor (name, color) {
    super()

    this.id = name
    this.selection.attr('class', `row`)

    this.icon = this.selection.append('i')
      .style('color', color)
      .classed('row-icon', true)

    this.selection.append('span')
      .attr('class', 'row-title')
      .text(name)
  }

  get active () {
    return this.icon.classed('icon-circle')
  }

  /**
   * Activate the row. Expected outcome is that the corresponding item
   * will be visible now.
   */
  set active (state) {
    this.icon.classed('icon-circle', state)
    this.icon.classed('icon-circle-empty', !state)
  }

  get na () {
    this.selection.classed('na')
  }

  /**
   * Not applicable, there is no data to show. The row is grayed out.
   */
  set na (state) {
    this.selection.classed('na', state)
  }

  addLink (url, tooltip) {
    let urlAnchor = this.selection.append('a')
        .attr('href', url)
        .attr('target', '_blank')
        .classed('row-url', true)

    urlAnchor.append('i')
      .classed('icon-link-ext', true)

    urlAnchor
      .on('mousemove', function () {
        d3.event.stopPropagation()
        tooltip.render(tt.parseText({ text: 'Show details' }))
        tt.moveTooltip(tooltip, d3.select(this), 'left')
      })
      .on('click', () => d3.event.stopPropagation())
  }

  addOnClick (fn) {
    super.addOnClick()
    this.selection.on('click', () => {
      this.active = !this.active
      fn({ id: this.id, state: this.active })
    })
  }

  click () {
    this.selection.on('click')()
  }
}
