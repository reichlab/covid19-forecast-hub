/**
 * Color related functions
 */

/**
 * Doc guard
 */
import * as d3 from 'd3'
import * as tinycolor from 'tinycolor2'

/**
 * Some pre generated palettes from http://tools.medialab.sciences-po.fr/iwanthue/
 */
export const colors30 = [
  '#eb9491',
  '#e26d67',
  '#f0574b',
  '#e3845e',
  '#e76b2e',
  '#c6925e',
  '#d88a2f',
  '#d2aa3b',
  '#d3c179',
  '#bfc83c',
  '#909d37',
  '#abd077',
  '#75c142',
  '#6c9e5b',
  '#4dc968',
  '#62c793',
  '#61daca',
  '#3cb8c0',
  '#5daade',
  '#568ced',
  '#9999dc',
  '#9c78ef',
  '#be87d4',
  '#db6dd8',
  '#e29cce',
  '#e165b7',
  '#ef5297',
  '#dc77a0',
  '#ec5778',
  '#cb7478'
]

export const colors50 = [
  '#d27878',
  '#de7a58',
  '#e96735',
  '#ed9d7d',
  '#d48232',
  '#b8844c',
  '#e5b06f',
  '#df9b2a',
  '#debf2e',
  '#d5c056',
  '#a59229',
  '#ccc17d',
  '#9a914f',
  '#94a231',
  '#b2c834',
  '#bdd461',
  '#b9cf84',
  '#8ca259',
  '#74a530',
  '#96dc5b',
  '#6e984c',
  '#69b92e',
  '#95cf73',
  '#3bab40',
  '#61d96a',
  '#77b97c',
  '#90da99',
  '#46a459',
  '#50d885',
  '#4a9a74',
  '#42dcaa',
  '#7fdcbf',
  '#4aba9e',
  '#46c9d2',
  '#5cb4e1',
  '#499ae1',
  '#4f8af1',
  '#8b94d4',
  '#8982e6',
  '#c4a8ef',
  '#b171ed',
  '#c87dd6',
  '#e364d2',
  '#eea7e0',
  '#c57dae',
  '#e464ae',
  '#eb5a88',
  '#e88ba1',
  '#f14c55',
  '#ea6368'
]

/**
 * Convert hex to rgba
 */
export function hexToRgba (hex: string, alpha: number): string {
  return tinycolor(hex).setAlpha(alpha).toRgbString()
}

/**
 * Return colormap of given size
 */
export function getColorMap (size: number): string[] {
  if (size > 30) {
    return colors50
  } else if (size > 20) {
    return colors30
  } else if (size > 10) {
    // @ts-ignore
    return d3.schemeCategory20 as string[]
  } else {
    // @ts-ignore
    return d3.schemeCategory10 as string[]
  }
}
