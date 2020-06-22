import * as ev from '../../../events'
import ControlButtons from './control-buttons'
import LegendDrawer from './legend-drawer'
import Component from '../../component'

/**
 * Chart controls
 * nav-drawers and buttons
 */
export default class ControlPanel extends Component {
  constructor (config) {
    super()
    this.selection.attr('class', 'd3f-controls')
    this.config = config

    // Add legend drawer
    this.legendDrawer = this.append(new LegendDrawer(config))

    // Buttons on the side of panel
    let sideButtons = this.append(new ControlButtons(config.tooltip, config.uuid))

    ev.addSub(config.uuid, ev.PANEL_TOGGLE, (msg, data) => {
      this.legendDrawer.hidden = !this.legendDrawer.hidden
      sideButtons.legendBtnState = !sideButtons.legendBtnState
    })

    // Turn on legend by default
    sideButtons.legendBtnState = true
  }

  plot (predictions, additional, config) {
    this.legendDrawer.plot(predictions, additional, config)
  }

  update (predictions) {
    this.legendDrawer.update(predictions)
  }
}
