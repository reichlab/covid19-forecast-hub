import Vue from 'vue'
import VueHead from 'vue-head'
import VueResource from 'vue-resource'

import App from './App'
import store from './store'

import 'bulma/css/bulma.css'
import 'font-awesome/css/font-awesome.css'
import './assets/please-wait.css'
import './assets/spinner.css'
import './assets/analytics.js'
import 'nprogress/nprogress.css'
import 'tablesort/tablesort.css'
import '../covid-d3-foresight/assets/fontello/fontello.css'
import './assets/favicons/favicon-16x16.png'
import './assets/favicons/favicon-32x32.png'
import './assets/favicons/favicon-96x96.png'
import './assets/favicons/favicon.ico'

Vue.use(VueHead)
Vue.use(VueResource)

Vue.create = options => new Vue(options)

Vue.create({
  el: 'body',
  store,
  components: {
    App
  }
})