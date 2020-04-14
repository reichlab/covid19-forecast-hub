import * as types from '../mutation-types'

// Initial state
const state = {
  show: true,
  data: [{
    title: 'Welcome to flusight',
    content: `Click <strong>Next</strong> to proceed. Click
                <strong>Finish</strong> to exit this demo.`,
    element: '',
    direction: ''
  }],
  pointer: 0
}

// getters
const getters = {
  currentIntro: (state, getters) => state.data[getters.introStep],
  introStep: state => state.pointer,
  introLength: state => state.data.length,
  introShow: state => state.show,
  introAtFirst: (state, getters) => getters.introStep === 0,
  introAtLast: (state, getters) => getters.introStep === getters.introLength - 1
}

// actions
const actions = {
  appendIntroItems ({ commit }, items) {
    items.forEach(item => commit(types.APPEND_INTRO_ITEM, item))
  },

  moveIntroStart ({ commit, dispatch }) {
    commit(types.RESET_INTRO_POINTER)
    commit(types.SHOW_INTRO)
  },

  moveIntroForward ({ commit, dispatch, getters }) {
    if (getters.introAtLast) commit(types.HIDE_INTRO)
    else commit(types.INCREMENT_INTRO_POINTER)
  },

  moveIntroBackward ({ commit, dispatch }) {
    commit(types.DECREMENT_INTRO_POINTER)
  },

  moveIntroFinish ({ commit }) {
    commit(types.HIDE_INTRO)
  }
}

// mutations
const mutations = {
  [types.INCREMENT_INTRO_POINTER] (state) {
    state.pointer += 1
  },

  [types.DECREMENT_INTRO_POINTER] (state) {
    state.pointer -= 1
  },

  [types.RESET_INTRO_POINTER] (state) {
    state.pointer = 0
  },

  [types.HIDE_INTRO] (state) {
    state.show = false
  },

  [types.SHOW_INTRO] (state) {
    state.show = true
  },

  [types.APPEND_INTRO_ITEM] (state, val) {
    state.data.push(val)
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
