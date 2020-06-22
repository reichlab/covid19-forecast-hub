import * as ev from '../../../events'
import colors from '../../../styles/modules/colors.json'
import DrawerRow from './drawer-row'
import ToggleButtons from './toggle-buttons'
import Component from '../../component'
import SearchBox from './search-box'
import * as tt from '../../../utilities/tooltip'

function makePredictionRow (p, tooltip) {
  let drawerRow = new DrawerRow(p.id, p.style.color)

  let ttText
  if (p.meta) {
    if (p.meta.url) {
      drawerRow.addLink(p.meta.url, tooltip)
    }
    ttText = tt.parseText({ title: p.meta.name, text: p.meta.description })
  } else {
    ttText = tt.parseText({ title: p.id, text: '' })
  }

  drawerRow.addTooltip(tooltip, ttText, 'left')
  drawerRow.active = !p.hidden
  return drawerRow
}

/**
 * Legend nav drawer
 */
export default class LegendDrawer extends Component {
  constructor (config) {
    super()

    this.selection.classed('legend-drawer', true)

    // Items above the controls (actual, observed, history)
    let topContainer = this.selection.append('div')

    let topItems = [
      {
        color: colors.actual,
        text: 'Actual',
        tooltipData: {
          title: 'Actual Data',
          text: 'Latest data available for the week'
        }
      },
      {
        color: colors.observed,
        text: 'Observed',
        tooltipData: {
          title: 'Observed Data',
          text: 'Data available for weeks when the predictions were made'
        }
      },
      {
        color: colors['history'],
        text: 'History',
        tooltipData: {
          title: 'Historical Data',
          text: 'Toggle historical data lines'
        }
      }
    ]

    // Add rows for top items
    this.topRowsMap = {}
    topItems.forEach(data => {
      let drawerRow = new DrawerRow(data.text, data.color)
      drawerRow.addOnClick(({ id, state }) => {
        ev.publish(config.uuid, ev.LEGEND_ITEM, { id, state })
      })
      drawerRow.addTooltip(config.tooltip, tt.parseText(data.tooltipData), 'left')
      drawerRow.active = true
      topContainer.append(() => drawerRow.node)
      this.topRowsMap[data.text.toLowerCase()] = drawerRow
    })

    // Control buttons (CI, show/hide, search)
    let middleContainer = this.selection.append('div')
        .attr('class', 'legend-middle-container')

    if (config.ci) {
      let ciRow = middleContainer.append('div')
          .attr('class', 'row control-row')
      ciRow.append('span').text('CI')

      let ciValues = [...config.ci.values, 'none']
      this.ciButtons = new ToggleButtons(ciValues)
      this.ciButtons.addTooltip(
        config.tooltip,
        tt.parseText({
          title: 'Confidence Interval',
          text: 'Select confidence interval for prediction markers'
        }), 'left')

      this.ciButtons.addOnClick(({ idx }) => {
        ev.publish(config.uuid, ev.LEGEND_CI, { idx: (ciValues.length - 1) === idx ? -1 : idx })
      })
      this.ciButtons.set(config.ci.idx)
      ciRow.append(() => this.ciButtons.node)
    }

    // Show / hide all
    let showHideRow = middleContainer.append('div')
        .attr('class', 'row control-row')
    showHideRow.append('span').text('Show')

    this.showHideButtons = new ToggleButtons(['all', 'none'])
    this.showHideButtons.addTooltip(
      config.tooltip,
      tt.parseText({
        title: 'Toggle visibility',
        text: 'Show / hide all predictions'
      }), 'left')

    this.showHideButtons.addOnClick(({ idx }) => {
      this.showHideAllItems(idx === 0)
    })
    showHideRow.append(() => this.showHideButtons.node)

    // Add search box
    this.searchBox = new SearchBox()
    middleContainer.append(() => this.searchBox.node)

    // Pinned model rows
    this.pinnedContainer = topContainer.append('div')

    // Model rows
    this.bottomContainer = this.selection.append('div')
      .attr('class', 'legend-bottom-container')

    this.tooltip = config.tooltip
    this.uuid = config.uuid
  }

  // Show / hide the "row items divs" while filtering with the search box
  showRows (states) {
    this.bottomRows.forEach((row, idx) => {
      row.hidden = !states[idx]
    })
  }

  // Show / hide all the items markers
  showHideAllItems (show) {
    this.bottomRows.forEach(row => {
      if (row.active !== show) {
        row.click()
      }
    })
  }

  plot (predictions, additional, config) {
    // Update the top items except pinned models
    for (let topId in this.topRowsMap) {
      this.topRowsMap[topId].hidden = !config[topId]
    }

    // Don't show search bar if predictions are less than or equal to maxNPreds
    let maxNPreds = 10
    if (predictions.length > maxNPreds) {
      this.searchBox.hidden = false

      // Bind search event
      this.searchBox.addKeyup(({ text }) => {
        let searchBase = predictions.map(p => {
          return `${p.id} ${p.meta.name} ${p.meta.description}`.toLowerCase()
        })
        this.showRows(searchBase.map(sb => sb.includes(text)))
      })
    } else {
      this.searchBox.hidden = true
    }

    // Plot models which are unpinned in the bottom section
    this.bottomContainer.selectAll('*').remove()
    this.bottomRows = predictions
      .filter(p => config.pinnedModels.indexOf(p.id) === -1)
      .map(p => {
        let drawerRow = makePredictionRow(p, this.tooltip)
        drawerRow.addOnClick(({ id, state }) => {
          this.showHideButtons.reset()
          ev.publish(this.uuid, ev.LEGEND_ITEM, { id, state })
        })

        this.bottomContainer.append(() => drawerRow.node)
        return drawerRow
      })

    // Handle pinned models separately
    this.pinnedContainer.selectAll('*').remove()
    this.pinnedRows = [
      ...predictions.filter(p => config.pinnedModels.indexOf(p.id) > -1),
      ...additional.filter(ad => ad.legend)
    ]
      .map(it => {
        let drawerRow = makePredictionRow(it, this.tooltip)
        drawerRow.addOnClick(({ id, state }) => {
          ev.publish(this.uuid, ev.LEGEND_ITEM, { id, state })
        })

        this.pinnedContainer.append(() => drawerRow.node)
        return drawerRow
      })
  }

  update (predictions) {
    predictions.forEach(p => {
      let row = this.bottomRows.find(r => r.id === p.id) || this.pinnedRows.find(r => r.id === p.id)
      if (row) {
        row.na = p.noData
      }
    })
  }
}
