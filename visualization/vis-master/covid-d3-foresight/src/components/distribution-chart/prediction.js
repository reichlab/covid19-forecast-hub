import * as d3 from 'd3'
import SComponent from '../s-component'
import { applyStyle } from '../../utilities/style'
import { kebabCase } from '../../utilities/misc'

/**
 * Prediction marker for distribution chart
 */
export default class Prediction extends SComponent {
  constructor ({ id, meta, style }) {
    super()
    this.selection
      .attr('class', 'prediction-group')
      .attr('id', kebabCase(id) + '-marker')

    this.selection.append('path')
      .attr('class', 'area-prediction')
      .style('fill', style.color)
    applyStyle(this.selection.select('.area-prediction'), style.area)

    this.selection.append('path')
      .attr('class', 'line-prediction')
      .style('stroke', style.color)
    applyStyle(this.selection.select('.line-prediction'), style.line)

    this.style = style
    this.id = id
    this.meta = meta

    // Tells if the prediction is hidden by some other component
    this._hidden = false
    // Tells if data is available to be shown for current time
    this.noData = true
  }

  plot (scales, curveData) {
    if (curveData.data === null) {
      // There is no data for current point, hide the markers without
      // setting exposed hidden flag
      this.noData = true
      this.hideMarkers()
    } else {
      this.noData = false
      if (!this.hidden) {
        // No one is hiding me
        this.showMarkers()
      }

      let line = d3.line()
          .x(d => scales.xScale(d[0]))
          .y(d => scales.yScale(d[1]))

      this.selection.select('.line-prediction')
        .datum(curveData.data)
        .transition()
        .duration(200)
        .attr('d', line)

      let area = d3.area()
          .x(d => scales.xScale(d[0]))
          .y1(d => scales.yScale(0))
          .y0(d => scales.yScale(d[1]))

      this.selection.select('.area-prediction')
        .datum(curveData.data)
        .transition()
        .duration(200)
        .attr('d', area)
    }
    this.displayedData = curveData.data
  }

  query (index) {
    return (!this.noData && !this.hidden && this.displayedData[index][1])
  }

  /**
   * Check if we are hidden
   */
  get hidden () {
    return this._hidden
  }

  set hidden (hide) {
    if (hide) {
      this.hideMarkers()
    } else {
      if (!this.noData) {
        this.showMarkers()
      }
    }
    this._hidden = hide
  }

  hideMarkers () {
    super.hidden = true
  }

  showMarkers () {
    super.hidden = false
  }

  /**
   * Remove the markers
   */
  clear () {
    super.clear()
    this.selection.remove()
  }
}
