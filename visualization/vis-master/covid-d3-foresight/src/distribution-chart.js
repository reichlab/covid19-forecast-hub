import * as d3 from 'd3'
import { XAxisDate } from './components/common/axis-x'
import ControlPanel from './components/common/control-panel'
import DistributionPanel from './components/distribution-chart/distribution-panel'
import Pointer from './components/distribution-chart/pointer'
import * as domains from './utilities/data/domains'
import Chart from './chart'
import { verifyDistChartData } from './utilities/data/verify'
import { getDistChartDataConfig } from './utilities/data/config'
import * as ev from './events'

export default class DistributionChart extends Chart {
  constructor (element, options = {}) {
    let defaultConfig = {
      pointType: 'week',
      confidenceIntervals: [],
      margin: {
        top: 5,
        right: 60,
        bottom: 80,
        left: 5
      }
    }

    let selection = d3.select(element)
        .attr('class', 'd3f-chart d3f-distribution-chart')
    super(selection, Object.assign({}, defaultConfig, options))

    // Initialize scales
    this.xScale = d3.scaleLinear().range([0, this.width])
    this.xScaleDate = d3.scaleTime().range([0, this.width])
    this.xScalePoint = d3.scalePoint().range([0, this.width])

    // Time axis for indicating current position
    this.xAxis = this.append(new XAxisDate(this.layout, {
      ...this.config.axes.x,
      tooltip: this.tooltip
    }))

    // create 4 panels and assign new svgs to them
    let panelMargin = {
      top: 5, right: 10, bottom: 70, left: 50
    }
    let panelHeight = this.height / 2
    let panelWidth = this.width / 2
    let panelPositions = [
      [0, 0],
      [0, panelHeight],
      [panelWidth, 0],
      [panelWidth, panelHeight]
    ]

    this.panels = panelPositions.map(pos => {
      let svg = this.svg.append('svg')
          .attr('x', pos[0])
          .attr('y', pos[1])
          .attr('width', panelWidth)
          .attr('height', panelHeight)
          .append('g')
          .attr('transform', `translate(${panelMargin.left}, ${panelMargin.top})`)

      let panel = new DistributionPanel({
        width: panelWidth - panelMargin.left - panelMargin.right,
        height: panelHeight - panelMargin.top - panelMargin.bottom
      }, { tooltip: this.tooltip })
      svg.append(() => panel.node)
      return panel
    })

    // Add dropdowns for curve selection
    this.dropdowns = panelPositions.map(pos => {
      let wrapperWrapper = this.selection.append('div')
      wrapperWrapper.style('text-align', 'center')

      let wrapper = wrapperWrapper.append('span')
      wrapper.attr('class', 'select is-small')
      let dd = wrapper.append('select')

      wrapperWrapper.style('position', 'absolute')
      wrapperWrapper.style('left', (pos[0] + panelMargin.left / 2) + 'px')
      wrapperWrapper.style('width', panelWidth + 'px')
      wrapperWrapper.style('top', (pos[1] + panelHeight - panelMargin.bottom + 30) + 'px')

      return dd
    })

    this.pointer = this.append(new Pointer(this.layout, { uuid: this.uuid }))
    this.controlPanel = new ControlPanel({ ci: false, tooltip: this.tooltip, uuid: this.uuid })
    this.selection.append(() => this.controlPanel.node)

    ev.addSub(this.uuid, ev.PANEL_MOVE_NEXT, (msg, data) => {
      // Since we can't do anything for the next index, we just send a notification
      let oldIdx = this.currentIdx
      let newIdx = this.deltaIndex(1)
      if (newIdx !== oldIdx) {
        ev.publish(this.uuid, ev.JUMP_TO_INDEX, newIdx)
      }
    })

    ev.addSub(this.uuid, ev.PANEL_MOVE_PREV, (msg, data) => {
      let oldIdx = this.currentIdx
      let newIdx = this.deltaIndex(-1)
      if (newIdx !== oldIdx) {
        ev.publish(this.uuid, ev.JUMP_TO_INDEX, newIdx)
      }
    })

    ev.addSub(this.uuid, ev.LEGEND_ITEM, (msg, { id, state }) => {
      this.panels.forEach(p => {
        let predMarker = p.predictions.find(p => p.id === id)
        if (predMarker) {
          predMarker.hidden = !state
        }
      })
    })
  }

  // plot data
  plot (data) {
    verifyDistChartData(data)
    let dataConfig = getDistChartDataConfig(data, this.config)
    this.ticks = dataConfig.ticks
    this.currentIdx = data.currentIdx

    this.dropdowns.forEach(dd => {
      dd.selectAll('*').remove()
      dataConfig.curveNames.forEach((cn, idx) => {
        let option = dd.append('option')
        option.text(cn)
        option.attr('value', idx)
      })
    })

    this.xScaleDate.domain(domains.xDate(data, dataConfig))
    this.xScalePoint.domain(domains.xPoint(data, dataConfig))
    this.xScale.domain(domains.x(data, dataConfig))

    this.xAxis.plot(this.scales)
    this.pointer.plot(this.scales, this.currentIdx)

    let yMaxima = domains.yCurveMaxima(data)

    // Provide curve data to the panels
    this.panels.forEach((p, idx) => {
      if (!p.selectedCurveIdx) {
        p.selectedCurveIdx = idx
        this.dropdowns[idx].property('value', idx)
      } else {
        this.dropdowns[idx].property('value', p.selectedCurveIdx)
      }
      p.plot(data, yMaxima)
    })

    // Add event listeners to dropdown
    this.dropdowns.forEach((dd, idx) => {
      let currentPanel = this.panels[idx]
      dd.on('change', function () {
        let selectedIdx = parseInt(d3.select(this).property('value'))
        currentPanel.selectedCurveIdx = selectedIdx
        currentPanel.plot(data, yMaxima)
      })
    })

    // Update models shown in control panel
    this.controlPanel.plot(this.panels[0].predictions, [], dataConfig)

    // Fade out models with no predictions
    this.controlPanel.update(this.panels[0].predictions)
  }
}
