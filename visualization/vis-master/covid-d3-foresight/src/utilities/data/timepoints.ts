/**
 * Functions for working with various timepoint types
 */

/**
 * Doc guard
 */
import * as mmwr from 'mmwr-week'
import * as moment from 'moment'
import * as d3 from 'd3'
import { Timepoint, TimepointId } from '../../interfaces'
import * as errors from '../errors'
import { parseText } from '../tooltip'
import { orArrays } from '../misc'

function parseWeek(d: Date): number {
  return parseInt(d3.timeFormat('%W')(d))
}

function parseMonth(d: Date): number {
  return parseInt(d3.timeFormat('%m')(d))
}

function isTimepoint(tp: any): boolean {
  return (tp !== null) && (typeof tp === 'object') && ('year' in tp)
}

function isDate(tp: any): boolean {
  return (tp instanceof Date)
}

function isString(tp: any): boolean {
  return (typeof tp === 'string' || tp instanceof String)
}

function stringToDate(tp: string): Date {
  return moment(tp).toDate()
}

/**
 * Parse timepoint to standard dictionary format
 */
function parseTimepoint(tp: Timepoint | Date | string, pointType: TimepointId): Timepoint {
  if (isTimepoint(tp)) {
    return tp as Timepoint
  }

  if (isString(tp)) {
    tp = stringToDate(tp as string)
  }

  if (isDate(tp)) {
    tp = tp as Date
    if (pointType === 'week') {
      return { year: tp.getFullYear(), week: parseWeek(tp) }
    } else if (pointType === 'mmwr-week') {
      let mdate = new mmwr.MMWRDate(0)
      mdate.fromJSDate(tp)
      return { year: mdate.year, week: mdate.week }
    } else if (pointType === 'biweek') {
      return { year: tp.getFullYear(), week: Math.floor(parseWeek(tp) / 2) }
    } else if (pointType === 'month') {
      return { year: tp.getFullYear(), month: parseMonth(tp) }
    } else {
      throw new errors.UnknownPointType()
    }
  } else {
    throw new errors.UnknownPointType()
  }
}

/**
 * Return ticks to show for the timepoints
 */
export function getTick(tp: Timepoint | Date | string, pointType: TimepointId): string | number {
  tp = parseTimepoint(tp, pointType)
  if ((pointType === 'week') || (pointType === 'mmwr-week') ) {
    return tp.week
  } if (pointType === 'biweek') {
    return tp.biweek
  } if (pointType === 'month') {
    return tp.month
  } else {
    throw new errors.UnknownPointType()
  }
}

/**
 * Return date time value for the timepoint
 */
export function getDateTime(tp: Timepoint | Date | string, pointType: TimepointId): Date {
  if (isString(tp)) {
    return stringToDate(tp as string)
  } else if (isDate(tp)) {
    return tp as Date
  } else if (isTimepoint(tp)) {
    tp = tp as Timepoint
    if (pointType === 'week') {
      return d3.timeParse('%Y-%W')(`${tp.year}-${tp.week}`)
    } else if (pointType === 'mmwr-week') {
      return (new mmwr.MMWRDate(tp.year, (tp as Timepoint).week)).toJSDate()
    } else if (pointType === 'biweek') {
      return d3.timeParse('%Y-%W')(`${tp.year}-${tp.biweek * 2}`)
    } else if (pointType === 'month') {
      return d3.timeParse('%Y-%m')(`${tp.year}-${tp.month}`)
    } else {
      throw new errors.UnknownPointType()
    }
  } else {
    throw new errors.UnknownPointType()
  }
}

/**
 * Parse data version times as JS datetimes
 */
export function parseDataVersionTimes(data, dataConfig) {
  if (dataConfig.predictions.versionTime) {
    return orArrays(data.models.map(m => {
      let preds = m.predictions.map(p => {
        if ((p === null) || (p.dataVersionTime === null)) {
          return null
        } else {
          return getDateTime(p.dataVersionTime, dataConfig.pointType)
        }
      })
      return preds
      }), (a, b) => a.valueOf() === b.valueOf())
  } else {
    // Otherwise use time from regular timepoints
    return data.timePoints.map(t => getDateTime(t, dataConfig.pointType))
  }
}
