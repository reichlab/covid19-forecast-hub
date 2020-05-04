import { expect } from 'chai'
import 'mocha'
import { orArrays } from '../src/utilities/misc'
import * as arrayEqual from 'array-equal'


describe('Array ORing', () => {
  it('should work for plain arrays', () => {
    let arrays = [
      [1, 2, 3],
      [1, 2, 3],
      [1, 2, 3],
      [1, 2, 3]
    ]

    expect(arrayEqual(orArrays(arrays), [1, 2, 3]))
  })

  it('should work for arrays with nulls', () => {
    let arrays = [
      [1, null, 3],
      [1, 2, 3],
      [1, 2, 3]
    ]

    expect(arrayEqual(orArrays(arrays), [1, 2, 3]))

    arrays = [
      [null, null, null],
      [1, 2, 3],
      [1, 2, 3]
    ]

    expect(arrayEqual(orArrays(arrays), [1, 2, 3]))
  })

  it('Should throw error with non equal items', () => {
    let arrays = [
      [1, null, 3],
      [1, 2, 3],
      [1, 2.3, 3]
    ]

    expect(() => { orArrays(arrays) }).to.throw('Non equal items in arrays')
  })
})
