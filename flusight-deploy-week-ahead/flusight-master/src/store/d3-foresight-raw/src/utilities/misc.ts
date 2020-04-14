/**
 * Module for miscellaneous functions
 */

/**
 * Doc guard
 */
import * as d3 from 'd3'
import { Position } from '../interfaces'
import { DocumentError } from './errors'

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
 * Return prediction objects which are present in modelsData. Clear the ones
 * which are absent.
 */
export function filterActivePredictions (predictions, modelsData) {
  let modelIds = modelsData.map(m => m.id)
  return predictions.filter(p => {
    if (modelIds.indexOf(p.id) === -1) {
      p.clear()
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
