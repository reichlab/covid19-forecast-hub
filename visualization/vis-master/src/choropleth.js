import 'topojson'
import Datamap from 'datamaps/dist/datamaps.usa'
import colormap from 'colormap'
import textures from 'textures'
import tinycolor from 'tinycolor2'
import * as d3 from 'd3'
import csv from 'csvtojson'

/**
 * Return sibling data for given element
 */

export const getSiblings = (element, data) => {
  let stateName = element.getAttribute('class').split(' ')[1]
  return data.filter(d => d.states.indexOf(stateName) > -1)[0]
}

/**
 * Return id mapping to region selector
 */
//export const getRegionId = region => parseInt(region.split(' ').pop())
export const getRegionId = (region, data) => {
  return data.findIndex(d => d.region == region) + 1
}
/**
 * Return non-sibling states
 */
export const getCousins = (element, data) => {
  let stateName = element.getAttribute('class').split(' ')[1]
  let states = []
  data.forEach(d => {
    if (d.states.indexOf(stateName) === -1) {
      states = states.concat(d.states)
    }
  })

  return states
}

export class ColorBar {
  constructor(svg, cmap) {
    let svgBB = svg.node().getBoundingClientRect()

    // Clear
    d3.select('.colorbar-group')
      .remove()

    let group = svg.append('g')
      .attr('class', 'colorbar-group')

    let bar = {
      height: 15,
      width: svgBB.width - 230,
      x: (svgBB.width * 3 / 4) - 150,
      y: svgBB.height - 43
    }
    // let bar = {
    //   height: 10,
    //   width: svgBB.width - 225,
    //   x: 0,
    //   y: 10
    // }
    let eachWidth = bar.width / cmap.length

    // Add rectangles
    for (let i = 0; i < cmap.length; i++) {
      group.append('rect')
        .attr('x', bar.x + i * eachWidth)
        .attr('y', bar.y)
        .attr('height', bar.height)
        .attr('width', eachWidth)
        .style('fill', cmap[cmap.length - 1 - i])
    }

    // //Add axis
    // let scale = d3.scaleLinear()
    //   .range([0, bar.width])
    let scale = d3.scaleLog()
      .base(10)
      .range([0, bar.width])
    group.append('g')
      .attr('class', 'axis axis-color')
      .attr('transform', 'translate(' + bar.x + ',' + (bar.y + bar.height) + ')')
    this.svg = svg
    this.scale = scale
  }

  // Update scale of colorbar
  update(range) {
    //console.log(range)
    this.scale.domain(range)
    let nticks = 5
    // Setup custom ticks
    if (range[0] < 0) {
      // Relative values
      nticks = 3
    }
    //console.log(range)

    let axis = d3.axisBottom(this.scale).ticks(4).tickFormat(d3.format(".2"))

    this.svg.select('.axis-color')
      .transition()
      .duration(200)
      .call(axis)
  }
}

// Draw map on given element
// Takes d3 instance
export default class Choropleth {
  constructor(elementId, regionHook) {
    let footBB = d3.select('.footer').node().getBoundingClientRect()
    let chartBB = d3.select('#' + elementId).node().getBoundingClientRect()

    let divWidth = chartBB.width
    let divHeight = window.innerHeight - chartBB.top - footBB.height

    // Padding offsets
    divHeight -= 60

    // Limits
    divHeight = Math.min(Math.max(215, divHeight), 275)
    divWidth = Math.min(divWidth, 400)

    // divHeight = Math.min(Math.max(390, divHeight), 400)
    // divWidth = Math.min(divWidth, 400)

    // Initialized datamap
    this.datamap = new Datamap({
      element: document.getElementById(elementId),
      scope: 'usa',
      height: divHeight,
      setProjection: (element, options) => {
        let projection = d3.geoAlbersUsa()
          .scale(divWidth)
          .translate([divWidth / 2, divHeight / 2 - 30])
        return {
          path: d3.geoPath().projection(projection),
          projection: projection
        }
      },
      fills: {
        defaultFill: '#ccc'
      },
      geographyConfig: {
        highlightOnHover: false,
        popupOnHover: false
      }
    })

    this.tooltip = d3.select('#choropleth-tooltip')
      .style('display', 'none')

    let svg = d3.select('#' + elementId + ' svg')
      .attr('height', divHeight)
      .attr('width', divWidth)

    this.selectedTexture = textures.lines()
      .size(10)
      .background('white')
    svg.call(this.selectedTexture)

    // Override datamaps css
    d3.select('#' + this.selectedTexture.id() + ' path')
      .style('stroke-width', '1px')

    this.width = svg.node().getBoundingClientRect().width
    this.height = svg.node().getBoundingClientRect().height
    this.svg = svg
    this.regionHook = regionHook
  }

  /**
   * Plot data on map
   * Triggered on:
   *   - Choropleth selector change
   *   - Season selector change
   */
  plot(data) {
    let svg = this.svg
    let regionHook = this.regionHook
    let tooltip = this.tooltip

    let minData = data.range[0]
    let maxData = data.range[1]
    //let maxData = 2000

    let limits = []
    let barLimits = []

    if (data.type === 'sequential') {
      // Set a 0 to max ranged colorscheme
      this.cmap = colormap({
        colormap: 'YIOrRd',
        nshades: 50,
        format: 'rgbaString'
      })

      limits = [maxData, .1]
      barLimits = [.1, maxData]
    } else if (data.type === 'diverging') {
      this.cmap = colormap({
        colormap: 'RdBu',
        nshades: 50,
        format: 'rgbaString'
      }).reverse()

      let extreme = Math.max(Math.abs(maxData), Math.abs(minData))

      limits = [extreme, -extreme]
      barLimits = [-extreme, extreme]
    }

    this.colorScale = d3.scaleLog()
      .base(10)
      .domain(limits)
      .range([0, this.cmap.length - 0.01])

    // Setup color bar
    this.colorBar = new ColorBar(svg, this.cmap)
    this.colorBar.update(barLimits)

    // Set on hover items
    d3.selectAll('.datamaps-subunit')
      .on('mouseover', function () {
        d3.selectAll('.datamaps-subunit')
          .filter(d => getCousins(this, data.data)
            .indexOf(d.id) > -1)
          .style('opacity', '0.4')
        tooltip.style('display', null)
      })
      .on('mouseout', function () {
        d3.selectAll('.datamaps-subunit')
          .filter(d => getCousins(this, data.data)
            .indexOf(d.id) > -1)
          .style('opacity', '1.0')
        tooltip.style('display', 'none')
      })
      .on('mousemove', function (event) {
        let [x, y] = d3.mouse(svg.node())
        let bb = svg.node().getBoundingClientRect()

        tooltip
          .style('top', (y + bb.top + 15) + 'px')
          .style('left', (x + bb.left + 15) + 'px')

        let stateName = this.getAttribute('class').split(' ')[1]
        let region = data.data
          .filter(d => (d.states.indexOf(stateName) > -1))[0].region
        let value = parseInt(this.getAttribute('data-value')).toLocaleString()
        tooltip.select('.value').text(value)
        tooltip.select('.region').text(region + ' : ' + stateName)
      })
      .on('click', function () {
        // Change the region selector)
        regionHook(getRegionId(getSiblings(this, data.data).region, data.data))
      })

    // Save data
    this.data = data.data
  }

  /**
   * Transition on week change and region highlight
   * Triggered on:
   *   - Week change
   *   - Region selector change
   */

   update(ids) {
    let data = this.data
    let colorScale = this.colorScale
    let selectedTexture = this.selectedTexture
    let cmap = this.cmap

    let highlightedStates = []
    if (ids.regionIdx >= 0) {
      highlightedStates = data[ids.regionIdx].states
    }

    // Update colors for given week
    data.map(d => {
      const popu = {}
      d3.csv("/static/locations.csv",function(data2) {
        data2.forEach(function(d) {
          popu[d.abbreviation] = d.population
        })
        let value = d.values[ids.weekIdx]/popu[d.states[0]]*100000
        let color = '#ccc'
        if (value !== -1) color = cmap[Math.floor(colorScale(value))]

        d.states.map(s => {
          let d3State = d3.select('.' + s)

          d3State.style('fill', color)
          d3State.attr('data-value', value)

          if (highlightedStates.indexOf(s) > -1) {
            // Setup selected pattern
            let strokeColor = tinycolor(color).getLuminance() < 0.5 ?
              'white' : '#444'

            d3.select('#' + selectedTexture.id() + ' rect')
              .attr('fill', color)

            d3.select('#' + selectedTexture.id() + ' path')
              .style('stroke', strokeColor)

            d3State.style('stroke', strokeColor)
              .style('stroke-opacity', 1)
              .style('fill', selectedTexture.url())
          } else {
            d3State.style('stroke', 'white')
              .style('stroke-opacity', 0)
          }
        })
      })
    })
  }
}




// const pop = {
      // 'US': 328728466.0, 
      // 'AL': 4903185.0, 
      // 'AK': 731545.0, 
      // 'AZ': 7278717.0, 
      // 'AR': 3017804.0, 
      // 'CA': 39512223.0, 
      // 'CO': 5758736.0, 
      // 'CT': 3565287.0, 
      // 'DE': 973764.0, 
      // 'DC': 705749.0, 
      // 'FL': 21477737.0, 
      // 'GA': 10617423.0, 
      // 'HI': 1415872.0, 
      // 'ID': 1787065.0, 
      // 'IL': 12671821.0, 
      // 'IN': 6732219.0, 
      // 'IA': 3155070.0, 
      // 'KS': 2913314.0, 
      // 'KY': 4467673.0, 
      // 'LA': 4648794.0, 
      // 'ME': 1344212.0, 
      // 'MD': 6045680.0, 
      // 'MA': 6892503.0, 
      // 'MI': 9986857.0, 
      // 'MN': 5639632.0, 
      // 'MS': 2976149.0, 
      // 'MO': 6626371.0, 
      // 'MT': 1068778.0, 
      // 'NE': 1934408.0, 
      // 'NV': 3080156.0, 
      // 'NH': 1359711.0, 
      // 'NJ': 8882190.0, 
      // 'NM': 2096829.0, 
      // 'NY': 19453561.0, 
      // 'NC': 10488084.0, 
      // 'ND': 762062.0, 
      // 'OH': 11689100.0, 
      // 'OK': 3956971.0, 
      // 'OR': 4217737.0, 
      // 'PA': 12801989.0, 
      // 'RI': 1059361.0, 
      // 'SC': 5148714.0, 
      // 'SD': 884659.0, 
      // 'TN': 6829174.0, 
      // 'TX': 28995881.0, 
      // 'UT': 3205958.0, 
      // 'VT': 623989.0, 
      // 'VA': 8535519.0, 
      // 'WA': 7614893.0, 
      // 'WV': 1792147.0, 
      // 'WI': 5822434.0, 
      // 'WY': 578759.0, 
      // 'AS': 55641.0, 
      // 'GU': 164229.0, 
      // 'MP': 55144.0, 
      // 'PR': 3754939.0,  
      // 'VI': 107268.0}