import Component from '../../component'

export default class SearchBox extends Component {
  constructor () {
    super()
    this.selection.classed('row', true)

    this.input = this.selection.append('input')
      .attr('class', 'search-input')
      .attr('type', 'text')
      .attr('placeholder', 'Filter models')

    this.hidden = true
  }

  addKeyup (fn) {
    this.input.keyup = null
    this.input.on('keyup', function () {
      fn({ text: this.value.toLowerCase() })
    })
  }
}
