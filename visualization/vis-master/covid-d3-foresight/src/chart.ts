import * as errors from './utilities/errors'
import Tooltip from './components/common/tooltip'
import { Event } from './interfaces'
import * as ev from './events'
import * as uuid from 'uuid/v4'

/**
 * Chart superclass
 */
export default class Chart {
  config: any
  width: number
  height: number
  svg: any
  tooltip: Tooltip
  selection: any
  onsetHeight: number
  xScale: any
  xScaleDate: any
  xScalePoint: any
  yScale: any
  currentIdx: number
  ticks: number[]
  uuid: string
  hooks: { [name: string]: any[] }

  constructor (selection, options = {}) {
    let defaultConfig = {
      axes: {
        x: {
          title: 'X',
          description: 'X axis',
          url: '#'
        },
        y: {
          title: 'Y',
          description: 'Y axis',
          url: '#'
        }
      },
      margin: {
        top: 5,
        right: 60,
        bottom: 70,
        left: 55
      },
      onset: false
    }
    this.config = (<any>Object).assign({}, defaultConfig, options)

    // Add space for onset
    this.onsetHeight = this.config.onset ? 30 : 0
    this.config.margin.bottom += this.onsetHeight

    let chartBB = selection.node().getBoundingClientRect()
    let divWidth = chartBB.width
    let divHeight = 480

    // Create blank chart
    this.width = divWidth - this.config.margin.left - this.config.margin.right
    this.height = divHeight - this.config.margin.top - this.config.margin.bottom

    // Add svg
    this.svg = selection.append('svg')
      .attr('width', this.width + this.config.margin.left + this.config.margin.right)
      .attr('height', this.height + this.config.margin.top + this.config.margin.bottom)
      .append('g')
      .attr('transform', `translate(${this.config.margin.left},${this.config.margin.top})`)

    this.tooltip = new Tooltip()
    selection.append(() => this.tooltip.node)

    this.selection = selection

    // Create a uuid for this instance
    this.uuid = uuid()

    // Current position in the time series
    this.currentIdx = -1
  }

  /**
   * Return layout related parameters
   */
  get layout () {
    return {
      width: this.width,
      height: this.height,
      totalHeight: this.height + this.onsetHeight
    }
  }

  get scales () {
    return {
      xScale: this.xScale,
      xScaleDate: this.xScaleDate,
      xScalePoint: this.xScalePoint,
      ticks: this.ticks,
      yScale: this.yScale
    }
  }

  /**
   * Return the value of currentIdx + delta as defined by the ticks
   */
  deltaIndex (delta) {
    return Math.max(Math.min(this.currentIdx + delta, this.scales.ticks.length - 1), 0)
  }

  plot (data) {}

  update (idx) {}

  /**
   * Append hook function if the hookName is supported and return subId
   */
  addHook (hookName: Event, fn): number {
    return ev.addSub(this.uuid, hookName, (msg, data) => fn(data))
  }

  /**
   * Remove specified subscription
   */
  removeHook (token) {
    ev.removeSub(token)
  }

  /**
   * Append another component to svg
   */
  append (component) {
    this.svg.append(() => component.node)
    return component
  }
}
