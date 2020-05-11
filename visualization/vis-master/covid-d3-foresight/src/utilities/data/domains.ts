/**
 * Functions for finding scale domains from data object
 */

/**
 * Doc guard
 */
import * as d3 from 'd3'
import * as errors from '../errors'
import { Range } from '../../interfaces'
import { getDateTime } from './timepoints'

/**
 * Return max of a pred object { point, high?, low? }
 */
function predMax(pred): number {
  let max = pred.point
  return max
}

/**
 * Return domain for y axis using limits of data
 */
export function y(data, dataConfig): Range {
  let min = 0
  let max = 0

  if (dataConfig.actual) {
    max = Math.max(max, ...data.actual.filter(d => d))
  }

  data.models.forEach(md => {
    md.predictions.forEach(p => {
      if (p) {
        max = Math.max(max, ...p.series.map(predMax))
        if (dataConfig.predictions.peak) {
          max = Math.max(max, predMax(p.peakValue))
        }
      }
    })
  })

  return [min, 1.3 * max]
}

/**
 * Return domain of x
 */
export function x(data, dataConfig): Range {
  return [0, data.timePoints.length - 1]
}

/**
 * Return domain for xdate
 */
export function xDate(data, dataConfig): Range {
  return d3.extent(data.timePoints.map(tp => {
    return getDateTime(tp, dataConfig.pointType)
  }))
}

/**
 * Return point scale domain
 */
export function xPoint(data, dataConfig): Range {
  return dataConfig.ticks
}

/**
 * Return domain for given curveid
 */
export function xCurve(data, curveIdx: number): Range {
  // This assumes an ordinal scale
  for (let i = 0; i < data.models.length; i++) {
    let curveData = data.models[i].curves[curveIdx].data
    if (curveData) {
      // Return the x series directly
      return curveData.map(d => d[0])
    }
  }
  return [0, 0]
}

/**
 * Get shared y limits for type of data
 */
export function yCurveMaxima(data) {
  let modelMaxes = data.models
    .filter(m => {
      // NOTE: Filtering based on the assumption that one model will have
      // /all/ the curves or none of them
      return m.curves.filter(c => c.data).length === m.curves.length
    })
    .map(m => {
      return m.curves.map(c => {
        return [c.data.length, Math.max(...c.data.map(d => d[1]))]
      })
    })

  // HACK: Simplify this
  // Identify curve type using the length of values in them
  let lengthToLimit = modelMaxes.reduce((acc, mm) => {
    mm.forEach(c => {
      acc[c[0]] = acc[c[0]] ? Math.max(acc[c[0]], c[1]) : c[1]
    })
    return acc
  }, {})

  let lengths = modelMaxes[0].map(c => c[0])
  return lengths.map(l => lengthToLimit[l])
}
