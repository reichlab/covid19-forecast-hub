/**
 * Module for miscellaneous functions
 */

/**
 * Doc guard
 */
import * as d3 from 'd3'
import { Position } from '../interfaces'
import { DocumentError } from './errors'

export function kebabCase(text) {
  return text.toLowerCase().replace(/ /g, '-')
}

/**
 * Return mouse position as absolute value for current view using the provided
 * d3Selection. The selection here matters because many of the elements with
 * mouse events are translated with respect to original svg. Most of the calls
 * to this function use .overlay as reference
 */
export function getMousePosition (d3Selection): Position {
  let [x, y] = d3.mouse(d3Selection.node())
  let bb = d3Selection.node().getBoundingClientRect()
  return [x + bb.left, y + bb.top]
}

/**
 * Return line objects which are present in lines. Clear the ones
 * which are absent.
 */
export function filterActiveLines (lineList, lines) {
  let lineIds = lines.map(l => l.id)
  return lineList.filter(l => {
    if (lineIds.indexOf(l.id) === -1) {
      l.clear()
      return false
    } else {
      return true
    }
  })
}

/**
 * Return uncle d3 selection
 */
export function selectUncle (currentSelector, uncleSelector: string) {
  let currentNode = d3.select(currentSelector).node()

  let walkUp = (cNode, pNode) => {
    if (pNode === null) {
      // We have reached the top level
      throw new DocumentError(`Selector ${uncleSelector} not found`)
    } else {
      let selection = d3.select(pNode).select(uncleSelector)
      if (selection.node() === null) {
        return walkUp(pNode, pNode.parentNode)
      } else {
        return selection
      }
    }
  }

  return walkUp(currentNode, currentNode.parentNode)
}

function allEqual (array: number[], eqFn): boolean {
  // @ts-ignore
  return !!array.reduce((acc, it) =>  eqFn(acc, it) ? acc : false)
}

/**
 * Take or of arrays, assume values at same indices to be the same
 */
export function orArrays (arrays: number[][], eqFn = (a, b) => a === b): number[] {
  let len = arrays[0].length

  // We can always take the largest array but lets not do that right now
  if (arrays.some(arr => arr.length !== len)) {
    throw new Error('Arrays of unequal length passed while oring')
  }

  return arrays[0].map((it, idx) => {
    let nonNulls = arrays.map(arr => arr[idx]).filter(d => d !== null)
    if (nonNulls.length > 0) {
      if (allEqual(nonNulls, eqFn)) {
        return nonNulls[0]
      } else {
        throw new Error('Non equal items in arrays')
      }
    } else {
      return null
    }
  })
}
