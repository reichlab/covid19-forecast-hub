import * as d3 from 'd3'
import textures from 'textures'
import * as tt from '../../utilities/tooltip'
import {
  selectUncle
} from '../../utilities/misc'
import SComponent from '../s-component'

/**
 * Simple linear X axis with informative label
 */
export class XAxis extends SComponent {
  constructor(layout, {
    tooltip,
    title,
    description,
    url
  }) {
    super()
    this.selection
      .attr('class', 'axis axis-x')
      .attr('transform', `translate(0, ${layout.height})`)

    let xText = this.selection
      .append('text')
      .attr('text-anchor', 'start')
      .attr('transform', `translate(${layout.width + 10}, -15)`)

    // Setup multiline text
    if (Array.isArray(title)) {
      xText.append('tspan')
        .text(title[0])
        .attr('x', 0)
      title.slice(1).forEach(txt => {
        xText.append('tspan')
          .text(txt)
          .attr('x', 0)
          .attr('dy', '1em')
      })
    } else {
      xText.append('tspan')
        .text(title)
        .attr('x', 0)
    }

    xText
      .on('mouseover', () => {
        tooltip.hidden = false
      })
      .on('mouseout', () => {
        tooltip.hidden = true
      })
      .on('mousemove', function () {
        tooltip.render(tt.parseText({
          text: description
        }))
        tt.moveTooltip(tooltip, selectUncle(this, '.overlay'), 'left')
      })

    if (url) {
      xText
        .style('cursor', 'pointer')
        .on('click', () => {
          window.open(url, '_blank')
        })
    }

    this.layout = layout
  }

  plot(scales, maxTicks) {
    let xAxis = d3.axisBottom(scales.xScale)
    let totalTicks = scales.xScale.domain().length
    if (maxTicks && (maxTicks < totalTicks / 2)) {
      // Show upto maxTicks ticks
      let showAt = parseInt(totalTicks / maxTicks)
      xAxis.tickValues(scales.xScale.domain().filter((d, i) => !(i % showAt)))
    }
    this.selection
      .transition().duration(200).call(xAxis)
  }
}

/**
 * X axis with week numbers, time and onset panel
 */
export class XAxisDate extends SComponent {
  constructor(layout, {
    tooltip,
    title,
    description,
    url
  }) {
    super()
    // Main axis with ticks below the onset panel
    this.selection.append('g')
      .attr('class', 'axis axis-x')
      .attr('transform', `translate(0,${layout.totalHeight})`)

    let axisXDate = this.selection.append('g')
      .attr('class', 'axis axis-x-date')
      .attr('transform', `translate(0,${layout.totalHeight + 25})`)

    let xText = axisXDate
      .append('text')
      .attr('text-anchor', 'start')
      .attr('transform', `translate(${layout.width + 10},-15)`)

    // Setup multiline text
    if (Array.isArray(title)) {
      xText.append('tspan')
        .text(title[0])
        .attr('x', 0)
      title.slice(1).forEach(txt => {
        xText.append('tspan')
          .text(txt)
          .attr('x', 0)
          .attr('dy', '1em')
      })
    } else {
      xText.append('tspan')
        .text(title)
        .attr('x', 0)
    }

    xText
      .on('mouseover', () => {
        tooltip.hidden = false
      })
      .on('mouseout', () => {
        tooltip.hidden = true
      })
      .on('mousemove', function () {
        tooltip.render(tt.parseText({
          text: description
        }))
        tt.moveTooltip(tooltip, selectUncle(this, '.overlay'), 'left')
      })

    if (url) {
      xText
        .style('cursor', 'pointer')
        .on('click', () => {
          window.open(url, '_blank')
        })
    }

    // Setup reverse axis (over onset offset)
    // Clone of axis above onset panel, without text
    this.selection.append('g')
      .attr('class', 'axis axis-x-ticks')
      .attr('transform', `translate(0, ${layout.height})`)

    // Create onset panel
    let onsetTexture = textures.lines()
      .lighter()
      .strokeWidth(0.5)
      .size(8)
      .stroke('#ccc')
    this.selection.call(onsetTexture)

    this.selection.append('rect')
      .attr('class', 'onset-texture')
      .attr('height', layout.totalHeight - layout.height)
      .attr('width', layout.width)
      .attr('x', 0)
      .attr('y', layout.height)
      .style('fill', onsetTexture.url())

    this.layout = layout
  }

  plot(scales) {
    let xAxis = d3.axisBottom(scales.xScalePoint)
      .tickValues(scales.xScalePoint.domain().filter((d, i) => !(i % 2)))

    let xAxisReverseTick = d3.axisTop(scales.xScalePoint)
      .tickValues(scales.xScalePoint.domain().filter((d, i) => !(i % 2)))

    let xAxisDate = d3.axisBottom(scales.xScaleDate)
      .ticks(d3.timeMonth)
      .tickFormat(d3.timeFormat('%b %d'))

    // Mobile view fix
    if (this.width < 420) {
      xAxisDate.ticks(2)
      xAxis.tickValues(scales.xScalePoint.domain().filter((d, i) => !(i % 10)))
    }

    this.selection.select('.axis-x')
      .transition().duration(200).call(xAxis)

    // Copy over ticks above the onsetpanel
    let tickOnlyAxis = this.selection.select('.axis-x-ticks')
      .transition().duration(200).call(xAxisReverseTick)

    tickOnlyAxis.selectAll('text').remove()

    this.selection.select('.axis-x-date')
      .transition().duration(200).call(xAxisDate)
  }
}