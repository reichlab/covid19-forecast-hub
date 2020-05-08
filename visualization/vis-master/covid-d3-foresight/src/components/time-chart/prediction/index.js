import SComponent from '../../s-component'
import LineMarker from './line-marker'
import OnsetMarker from './onset-marker'
import PeakMarker from './peak-marker'

/**
 * Prediction marker with following components
 * - Area
 * - Line and dots
 * - Onset
 * - Peak
 */
export default class Prediction extends SComponent {
  constructor({
    id,
    meta,
    onsetY,
    cid,
    tooltip,
    onset,
    peak,
    style
  }) {
    super()

    this.lineMarker = this.append(new LineMarker(id, style))
    if (onset) {
      this.onsetMarker = this.append(new OnsetMarker(id, onsetY, style))
    }
    if (peak) {
      this.peakMarker = this.append(new PeakMarker(id, style))
    }

    this.style = style
    this.id = id
    this.meta = meta
    this.cid = cid
    this.tooltip = tooltip
    this.show = {
      onset: onset,
      peak: peak
    }

    // Tells if the prediction is hidden by some other component
    this._hidden = false
    // Tells if data is available to be shown for current time
    this.noData = true
  }

  plot(scales, modelData) {
    this.modelData = modelData
    this.displayedData = Array(this.modelData.length).fill(false)
    this.scales = scales
  }

  get config() {
    return {
      scales: this.scales,
      id: this.id,
      meta: this.meta,
      style: this.style,
      cid: this.cid,
      tooltip: this.tooltip
    }
  }

  update(idx) {
    let currData = this.modelData[idx]
    if (currData === null) {
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

      if (this.show.onset) {
        this.onsetMarker.move(this.config, currData.onsetTime)
      }
      if (this.show.peak) {
        this.peakMarker.move(this.config, currData.peakTime, currData.peakValue)
      }

      // Move main pointers
      let series = []
      let idxOverflow = Math.min(0, this.modelData.length - (idx + currData.series.length))
      let displayLimit = currData.series.length - idxOverflow

      for (let i = 0; i < displayLimit; i++) {
        series.push({
          index: i + idx + 1,
          point: currData.series[i].point,
          low: this.cid === -1 ? currData.series[i].point : currData.series[i].low[this.cid],
          high: this.cid === -1 ? currData.series[i].point : currData.series[i].high[this.cid]
        })
      }

      // Save indexed data for query
      this.displayedData = Array(this.modelData.length).fill(false)
      series.forEach(d => {
        this.displayedData[d.index] = d.point
      })

      this.lineMarker.move(this.config, series)
    }
  }

  /**
   * Check if we are hidden
   */
  get hidden() {
    return this._hidden
  }

  set hidden(hide) {
    if (hide) {
      this.hideMarkers()
    } else {
      if (!this.noData) {
        this.showMarkers()
      }
    }
    this._hidden = hide
  }

  hideMarkers() {
    if (this.show.onset) {
      this.onsetMarker.hidden = true
    }
    if (this.show.peak) {
      this.peakMarker.hidden = true
    }
    this.lineMarker.hidden = true
  }

  showMarkers() {
    if (this.show.onset) {
      this.onsetMarker.hidden = false
    }
    if (this.show.peak) {
      this.peakMarker.hidden = false
    }
    this.lineMarker.hidden = false
  }

  /**
   * Remove the markers
   */
  clear() {
    super.clear()
    this.selection.remove()
  }

  /**
   * Ask if we have something to show at the index
   */
  query(idx) {
    // Don't show anything if predictions are hidden
    return (!this.noData && !this.hidden && this.displayedData[idx])
  }

  /**
   * Return index of asked idx among displayedData items
   */
  displayedIdx(idx) {
    for (let i = 0; i < this.displayedData.length; i++) {
      if (this.displayedData[i] !== false) return (idx - i)
    }
    return null
  }
}