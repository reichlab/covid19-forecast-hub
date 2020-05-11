import * as tt from '../../../utilities/tooltip'
import * as colors from '../../../utilities/colors'
import { selectUncle, kebabCase } from '../../../utilities/misc'
import SComponent from '../../s-component'

export default class OnsetMarker extends SComponent {
  constructor (id, onsetY, style) {
    super()
    this.selection
      .attr('class', 'onset-group')
      .attr('id', kebabCase(id) + '-marker')

    let color = style.color
    let stp = 6
    let colorPoint = colors.hexToRgba(color, 0.8)
    let colorRange = colors.hexToRgba(color, 0.6)

    this.selection.append('line')
      .attr('y1', onsetY)
      .attr('y2', onsetY)
      .attr('class', 'range onset-range')
      .style('stroke', colorRange)

    this.selection.append('line')
      .attr('y1', onsetY - stp / 2)
      .attr('y2', onsetY + stp / 2)
      .attr('class', 'stopper onset-stopper onset-low')
      .style('stroke', colorRange)

    this.selection.append('line')
      .attr('y1', onsetY - stp / 2)
      .attr('y2', onsetY + stp / 2)
      .attr('class', 'stopper onset-stopper onset-high')
      .style('stroke', colorRange)

    this.point = this.selection.append('circle')
      .attr('r', 3)
      .attr('cy', onsetY)
      .attr('class', 'onset-mark')
      .style('stroke', 'transparent')
      .style('fill', colorPoint)

    this.color = color
  }

  set highlight (state) {
    let colorHover = colors.hexToRgba(this.color, 0.3)

    this.point
      .transition()
      .duration(200)
      .style('stroke', state ? colorHover : 'transparent')

    this.selection.selectAll('line')
      .transition()
      .duration(200)
      .style('stroke-width', state ? '2px' : '1px')
  }

  move (cfg, onset) {
    this.point
      .transition()
      .duration(200)
      .attr('cx', cfg.scales.xScale(onset.point))

    this.point
      .on('mouseover', () => {
        this.highlight = true
        cfg.tooltip.hidden = false
        cfg.tooltip.render(tt.parsePoint({
          title: cfg.id,
          values: [{ key: 'Onset Time', value: cfg.scales.ticks[onset.point] }],
          color: this.color
        }))
      })
      .on('mouseout', () => {
        this.highlight = false
        cfg.tooltip.hidden = true
      })
      .on('mousemove', function () {
        tt.moveTooltip(cfg.tooltip, selectUncle(this, '.overlay'))
      })

    if (cfg.cid === -1) {
      this.selection.selectAll('line')
        .attr('display', 'none')
    } else {
      this.selection.selectAll('line')
        .attr('display', null)

      this.selection.select('.onset-range')
        .transition()
        .duration(200)
        .attr('x1', cfg.scales.xScale(onset.low[cfg.cid]))
        .attr('x2', cfg.scales.xScale(onset.high[cfg.cid]))

      this.selection.select('.onset-low')
        .transition()
        .duration(200)
        .attr('x1', cfg.scales.xScale(onset.low[cfg.cid]))
        .attr('x2', cfg.scales.xScale(onset.low[cfg.cid]))

      this.selection.select('.onset-high')
        .transition()
        .duration(200)
        .attr('x1', cfg.scales.xScale(onset.high[cfg.cid]))
        .attr('x2', cfg.scales.xScale(onset.high[cfg.cid]))
    }
  }
}
