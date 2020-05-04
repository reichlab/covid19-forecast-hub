import * as d3 from 'd3'
import { XAxis } from '../common/axis-x'
import { YAxis } from '../common/axis-y'
import Prediction from './prediction'
import * as domains from '../../utilities/data/domains'
import Overlay from './overlay'
import NoPredText from './no-pred-text'
import * as colors from '../../utilities/colors'
import { filterActiveLines } from '../../utilities/misc'
import SComponent from '../s-component'

/**
 * A panel displaying distributions for one curve
 */
export default class DistributionPanel extends SComponent {
  constructor (layout, { tooltip }) {
    super()
    this.xScale = d3.scalePoint().range([0, layout.width])
    this.yScale = d3.scaleLinear().range([layout.height, 0])
    this.xAxis = this.append(new XAxis(layout, { tooltip }))
    this.yAxis = this.append(new YAxis(layout, {
      title: 'Probability',
      description: 'Probability assigned to x-axis bins',
      tooltip
    }))

    this.predictions = []
    this.selectedCurveIdx = null
    this.tooltip = tooltip
    this.layout = layout
    this.overlay = this.append(new Overlay(layout, { tooltip }))
    this.noPredText = this.append(new NoPredText())
  }

  get scales () {
    return {
      xScale: this.xScale,
      yScale: this.yScale
    }
  }

  plot (data, yLimits) {
    this.xScale.domain(domains.xCurve(data, this.selectedCurveIdx))
    this.yScale.domain([0, yLimits[this.selectedCurveIdx]])

    this.xAxis.plot(this.scales, 10)
    this.yAxis.plot(this.scales, 5)

    // Setup colormap
    this.colors = colors.getColorMap(data.models.length)

    // Clear markers not needed
    this.predictions = filterActiveLines(this.predictions, data.models)

    // Generate markers for predictions if not already there
    // Assume unique model ids
    data.models.forEach((m, idx) => {
      let predMarker
      let markerIndex = this.predictions.findIndex(p => p.id === m.id)
      if (markerIndex === -1) {
        // The marker is not present from previous calls to plot
        predMarker = new Prediction({
          id: m.id,
          meta: m.meta,
          style: { color: this.colors[idx], ...m.style }
        })
        this.append(predMarker)
        this.predictions.push(predMarker)
      } else {
        predMarker = this.predictions[markerIndex]
      }
      predMarker.plot(this.scales, m.curves[this.selectedCurveIdx])
    })

    this.overlay.plot(this.scales, this.predictions)

    // Check if all markers have noData. That means we can show NA text.
    this.noPredText.hidden = (this.predictions.filter(p => p.noData).length !== this.predictions.length)
  }
}
