/**
 * Some utilities
 */

const fs = require('fs')
const yaml = require('js-yaml')

/**
 * Check if a is subset of b
 */
const isSubset = (a, b) => {
  if (a.length <= b.length) {
    for(let i = 0; i < a.length; i++) {
      if (b.indexOf(a[i]) === -1) {
        return false
      }
    }
    return true
  } else {
    return false
  }
}

/**
 * Return unique of array
 */
const unique = a => {
  let hasNaN = false

  let uniqueItems = a.reduce(function (acc, it) {
    if (Object.is(NaN, it)) {
      hasNaN = true
    } else if (acc.indexOf(it) === -1) {
      acc.push(it)
    }
    return acc
  }, [])

  return hasNaN ? [...uniqueItems, NaN] : uniqueItems
}

const writeLines = (lines, fileName) => {
  fs.writeFile(fileName, lines.join('\n'), err => {
    if (err) { throw err }
    console.log(` > ${fileName} written`)
  })
}

const readYamlFile = fileName => {
  return yaml.safeLoad(fs.readFileSync(fileName, 'utf8'))
}

const writeYamlFile = (data, filename) => {
  return fs.writeFileSync(filename, yaml.safeDump(data, {
    styles: {
      '!!bool': 'uppercase',
      '!!null': 'uppercase'
    }
  }))
}

const arange = (start, end, gap) => {
  let len = 1 + ((end - start) / gap)
  return [...Array(len).keys()].map(i => start + gap * i)
}

const isClose = (a, b, tol = Number.EPSILON) => Math.abs(a - b) < tol

/**
 * Clip number in a range
 */
const clip = (x, lo, hi, tol = Number.EPSILON) => {
  if (isNaN(x)) return x
  x = x < (lo + tol) ? lo : x
  x = x > (hi - tol) ? hi : x
  return x
}

module.exports.isSubset = isSubset
module.exports.unique = unique
module.exports.writeLines = writeLines
module.exports.readYamlFile = readYamlFile
module.exports.writeYamlFile = writeYamlFile
module.exports.arange = arange
module.exports.isClose = isClose
module.exports.clip = clip
