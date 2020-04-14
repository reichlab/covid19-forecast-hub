// Module for interacting with zoltar

const rp = require('request-promise-native')
const buildUrl = require('build-url')

async function get (url) {
  return rp(url, { json: true })
}

function jsonToCsv (json) {
  let lines = ['Location,Target,Type,Unit,Bin_start_incl,Bin_end_notincl,Value']

  for (let ldata of json.locations) {
    let location = ldata.name
    for (let tdata of ldata.targets) {
      let target = tdata.name
      lines.push(`${location},${target},Point,${tdata.unit},NA,NA,${tdata.point}`)
      for (let bin of tdata.bins) {
        lines.push(`${location},${target},Bin,${tdata.unit},${bin[0]},${bin[1]},${bin[2]}`)
      }
    }
  }
  return lines.join('\n')
}

function proxifyObject (obj, root) {
  let handler = {
    get (target, propKey, receiver) {
      let value = target[propKey]

      switch (propKey.toString()) {
        case 'url':
          return value
        case 'csv':
          {
            if ('forecast_data' in target) {
              return (async () => {
                let csvString = jsonToCsv(await get(target['forecast_data']))
                return csvString
              })()
            } else {
              throw new Error('This is not a forecast object')
            }
          }
      }

      if (typeof value === 'string' && (value.toString()).startsWith(root)) {
        return (async () => {
          let resp = await get(value)
          return proxifyObject(resp, root)
        })()
      } else if (typeof value === 'object') {
        return proxifyObject(value, root)
      } else {
        return value
      }
    }
  }

  return new Proxy(obj, handler)
}

function zoltar (rootUrl) {
  let baseObject = {
    projects: `${rootUrl}/projects`
  }
  return proxifyObject(baseObject, rootUrl)
}

module.exports.zoltar = zoltar
