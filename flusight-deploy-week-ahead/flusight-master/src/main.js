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
import 'd3-foresight/assets/fontello/fontello.css'

import './assets/favicons/apple-touch-icon-114x114.png'
import './assets/favicons/apple-touch-icon-120x120.png'
import './assets/favicons/apple-touch-icon-144x144.png'
import './assets/favicons/apple-touch-icon-152x152.png'
import './assets/favicons/apple-touch-icon-57x57.png'
import './assets/favicons/apple-touch-icon-60x60.png'
import './assets/favicons/apple-touch-icon-72x72.png'
import './assets/favicons/apple-touch-icon-76x76.png'
import './assets/favicons/favicon-128x128.png'
import './assets/favicons/favicon-16x16.png'
import './assets/favicons/favicon-196x196.png'
import './assets/favicons/favicon-32x32.png'
import './assets/favicons/favicon-96x96.png'
import './assets/favicons/favicon.ico'
import './assets/favicons/mstile-144x144.png'
import './assets/favicons/mstile-150x150.png'
import './assets/favicons/mstile-310x150.png'
import './assets/favicons/mstile-310x310.png'
import './assets/favicons/mstile-70x70.png'

Vue.use(VueHead)
Vue.use(VueResource)

Vue.create = options => new Vue(options)

Vue.create({
  el: 'body',
  store,
  components: { App }
})
