import * as tt from '../../utilities/tooltip'
import { selectUncle } from '../../utilities/misc'
import SComponent from '../s-component'

/**
 * Baseline
 */
export default class Baseline extends SComponent {
  constructor (layout, { tooltip, text, description, url }) {
    super()
    this.selection.attr('class', 'baseline-group')

    this.line = this.selection.append('line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', layout.width)
      .attr('y2', 0)
      .attr('class', 'baseline')

    this.text = this.selection.append('text')
      .attr('transform', `translate(${layout.width + 10}, 0)`)

    // Setup multiline text
    if (Array.isArray(text)) {
      this.text.append('tspan')
        .text(text[0])
        .attr('x', 0)
      text.slice(1).forEach(txt => {
        this.text.append('tspan')
          .text(txt)
          .attr('x', 0)
          .attr('dy', '1em')
      })
    } else {
      this.text.append('tspan')
        .text(text)
        .attr('x', 0)
    }

    this.text
      .on('mouseover', () => { tooltip.hidden = false })
      .on('mouseout', () => { tooltip.hidden = true })
      .on('mousemove', function () {
        tooltip.render(tt.parseText({ text: description }))
        tt.moveTooltip(tooltip, selectUncle(this, '.overlay'), 'left')
      })

    if (url) {
      this.text
        .style('cursor', 'pointer')
        .on('click', () => {
          window.open(url, '_blank')
        })
    }
  }

  plot (scales, baseline) {
    if (baseline) {
      this.hidden = false
    } else {
      this.hidden = true
      return
    }

    this.line
      .transition()
      .duration(200)
      .attr('y1', scales.yScale(baseline))
      .attr('y2', scales.yScale(baseline))

    this.text
      .transition()
      .duration(200)
      .attr('dy', scales.yScale(baseline))
  }
}
