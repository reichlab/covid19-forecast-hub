import Component from '../../component'

/**
 * Set of horizontally arranged buttons with only one active at a time
 */
export default class ToggleButtons extends Component {
  constructor (texts) {
    super()
    this.selection.classed('toggle-group', true)

    this.buttons = texts.map(txt => {
      return this.selection.append('span')
        .classed('toggle-button', true)
        .text(txt)
    })
  }

  addOnClick (fn) {
    super.addOnClick()
    let that = this
    this.buttons.forEach((btn, idx) => {
      btn.on('click', function () {
        fn({ idx })
        that.reset()
        that.set(idx)
      })
    })
  }

  set (idx) {
    this.buttons[idx].classed('selected', true)
  }

  unset (idx) {
    this.buttons[idx].classed('selected', false)
  }

  reset () {
    this.buttons.forEach((btn, idx) => this.unset(idx))
  }
}
