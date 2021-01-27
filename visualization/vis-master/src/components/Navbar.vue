<style lang="scss" scoped>

@import url('https://fonts.googleapis.com/css?family=Open+Sans:800');
@import url('https://fonts.googleapis.com/css?family=Source+Sans+Pro:700');

/// Removes a specific item from a list.
/// @author Hugo Giraudel
/// @param {list} $list List.
/// @param {integer} $index Index.
/// @return {list} Updated list.
@function remove-nth($list, $index) {

  $result: null;

  @if type-of($index) != number {
    @warn "$index: #{quote($index)} is not a number for `remove-nth`.";
  }
  @else if $index == 0 {
    @warn "List index 0 must be a non-zero integer for `remove-nth`.";
  }
  @else if abs($index) > length($list) {
    @warn "List index is #{$index} but list is only #{length($list)} item long for `remove-nth`.";
  }
  @else {

    $result: ();
    $index: if($index < 0, length($list) + $index + 1, $index);

    @for $i from 1 through length($list) {

      @if $i != $index {
        $result: append($result, nth($list, $i));
      }

    }

  }

  @return $result;

}

/// Gets a value from a map.
/// @author Hugo Giraudel
/// @param {map} $map Map.
/// @param {string} $keys Key(s).
/// @return {string} Value.
@function val($map, $keys...) {

  @if nth($keys, 1) == null {
    $keys: remove-nth($keys, 1);
  }

  @each $key in $keys {
    $map: map-get($map, $key);
  }

  @return $map;

}

/// Gets a font value.
/// @param {string} $keys Key(s).
/// @return {string} Value.
@function _font($keys...) {
  @return val($font, $keys...);
}

/// Gets a palette value.
/// @param {string} $keys Key(s).
/// @return {string} Value.
@function _palette($keys...) {
  @return val($palette, $keys...);
}

$font: (
  primary: ("Lato", Helvetica, Arial, sans-serif),
  monospace: (Monaco, courier, monospace)
);

// Palette.
$palette: (
  primary:           #424b5f,
  secondary:         #283040,
  meta:              #67758d,
  border:            #dee5ef,
  bg:                #f7f9fb,
  note:              #fcb41d,
  important:         #fc381d,
  accent:            #004e92,
  accent-alt:        #000428,
);

/**
 * Site Header
 */
.site-header {
  background: #fff;
  padding-bottom: 1.25em;
  padding-top: 1.125em;
  padding-left: 3vw;
  padding-right: 3vw;
  align-self: center;
}

.site-header-inside {
  -webkit-box-align: center;
  -ms-flex-align: center;
  align-items: center;
  display: -webkit-box;
  display: -ms-flexbox;
  display: flex;
}
.button {
  font-family: "Lato", Helvetica, Arial, sans-serif;
text-rendering: optimizeLegibility;
-webkit-font-smoothing: antialiased;
-webkit-box-direction: normal;
list-style: none;
background-color: #004e92;
border: 2px solid #004e92;
border-radius: 1.75em;
box-sizing: border-box;
color: #fff;
display: inline-block;
font-size: 14px;
font-weight: bold;
letter-spacing: 0.035em;
line-height: 1.2;
text-align: center;
text-decoration: none;
transition: .3s ease;
vertical-align: middle;
padding-bottom: 0.5em;
padding-top: 0.5em;
padding-left: 1.25em;
padding-right: 1.25em;
}

.button:hover {
  font-family: "Lato", Helvetica, Arial, sans-serif;
text-rendering: optimizeLegibility;
-webkit-font-smoothing: antialiased;
-webkit-box-direction: normal;
list-style: none;
border: 2px solid #004e92;
border-radius: 1.75em;
box-sizing: border-box;
display: inline-block;
font-size: 14px;
font-weight: bold;
letter-spacing: 0.035em;
line-height: 1.2;
text-align: center;
text-decoration: none;
transition: .3s ease;
vertical-align: middle;
padding-bottom: 0.5em;
padding-top: 0.5em;
background-color: transparent;
color: #004e92;
outline: 0;
padding-left: 1.25em;
padding-right: 1.25em;
}

.inner {
      margin-left: auto;
    margin-right: auto;
    max-width: 1200px;
}

.site-branding {
  -webkit-box-flex: 0;
  -ms-flex: 0 1 auto;
  flex: 0 1 auto;

  a {
    border: 0;
    color: inherit;
    display: inline-block;
  }
}

.site-title {
  color: _palette(secondary);
  font-size: 1.75rem;
  font-weight: bold;
  line-height: 1.2;
  margin: 0;
}

.site-logo {
  margin: 0;

  img {
    max-height: 55px;
  }
}

.site-navigation {
  margin-left: auto;
}

.menu,
.submenu {
  list-style: none;
  margin: 0;
  padding: 0;
}

.menu-item {
  position: relative;

  &.current-menu-item {
    color: _palette(accent);
  }

  a {
    &:not(.button) {
      border: 0;
      color: inherit;
      display: inline-block;
      font-size: 14px;
      line-height: 1.5;

      &:hover {
        color: _palette(accent);
      }
    }
  }
}

.menu-toggle {
  display: none;
}

@media only screen and (min-width: 801px) {
  .menu {
    -webkit-box-align: center;
    -ms-flex-align: center;
    align-items: center;
    display: -webkit-box;
    display: -ms-flexbox;
    display: flex;
  }

  .menu-item {
    margin-left: 20px;
    padding-bottom: 0.1875em;
    padding-top: 0.1875em;

    a {
      padding-bottom: 0.5em;
      padding-top: 0.5em;

      &.button:not(.button-icon) {
        padding-left: 1.25em;
        padding-right: 1.25em;
      }
    }

    &.has-children > a {
      padding-right: 15px;
      position: relative;

      &:after {
        background: 0;
        border-color: currentColor;
        border-style: solid;
        border-width: 1px 1px 0 0;
        box-sizing: border-box;
        content: "";
        height: 6px;
        position: absolute;
        right: 0;
        top: 50%;
        width: 6px;
        -webkit-transform: translateY(-50%) rotate(135deg);
        transform: translateY(-50%) rotate(135deg);
      }

      &.button:not(.button-icon) {
        padding-right: 2.25em;

        &:after {
          right: 1.25em;
        }
      }
    }
  }

  .submenu {
    background: #fff;
    border: 1px solid _palette(border);
    border-radius: 3px;
    left: 0;
    min-width: 180px;
    opacity: 0;
    padding: 0.75em 0;
    position: absolute;
    text-align: left;
    top: 100%;
    -webkit-transition: opacity .2s, visibility 0s .2s;
    transition: opacity .2s, visibility 0s .2s;
    visibility: hidden;
    width: 100%;
    z-index: 99;
  }

  .menu-item {
    .submenu-toggle {
      display: none;
    }

    &.has-children:hover > .submenu {
      opacity: 1;
      -webkit-transition: margin .3s, opacity .2s;
      transition: margin .3s, opacity .2s;
      visibility: visible;
    }
  }

  .submenu {
    .menu-item {
      display: block;
      margin: 0;
      padding: 0 15px;
    }

    a {
      &:not(.button-icon) {
        display: block;
      }

      &.button:not(.button-icon) {
        margin: 0.5em 0;
      }
    }
  }
}

@media only screen and (max-width: 800px) {
  .site {
    overflow: hidden;
    position: relative;
  }

  .site-branding {
    margin-right: 10px;
  }

  .site-header {
    &:after {
      background: rgba(_palette(primary),.6);
      content: "";
      height: 100vh;
      left: 0;
      opacity: 0;
      position: absolute;
      top: 0;
      -webkit-transition: opacity .15s ease-in-out,visibility 0s ease-in-out .15s;
      transition: opacity .15s ease-in-out,visibility 0s ease-in-out .15s;
      visibility: hidden;
      width: 100%;
      z-index: 998;
    }
  }

  #menu-open {
    display: block;
    margin-left: auto;
  }

  .site-navigation {
    background: #fff;
    box-sizing: border-box;
    height: 100vh;
    margin: 0;
    max-width: 360px;
    -webkit-overflow-scrolling: touch;
    position: absolute;
    right: -100%;
    top: 0;
    -webkit-transition: right .3s ease-in-out, visibility 0s .3s ease-in-out;
    transition: right .3s ease-in-out, visibility 0s .3s ease-in-out;
    visibility: hidden;
    width: 100%;
    z-index: 999;
  }

  .site-nav-inside {
    height: 100%;
    overflow: auto;
    -webkit-overflow-scrolling: touch;
    position: relative;
  }

  .menu--opened {
    .site {
      height: 100%;
      left: 0;
      overflow: hidden;
      position: fixed;
      top: 0;
      -webkit-transform: translate3d(0, 0, 0);
      transform: translate3d(0, 0, 0);
      width: 100%;
      z-index: 997;
    }

    .site-navigation {
      right: 0;
      -webkit-transition: right .3s ease-in-out;
      transition: right .3s ease-in-out;
      visibility: visible;
    }

    .site-header:after {
      opacity: 1;
      -webkit-transition-delay: 0s;
      transition-delay: 0s;
      visibility: visible;
    }
  }

  #menu-close {
    display: block;
    position: absolute;
    right: 3vw;
    top: 1.125rem;
  }

  .menu {
    padding: 4.5rem 3vw 3rem;
  }

  .submenu {
    border-top: 1px solid _palette(border);
    display: none;
    padding-left: 15px;
  
    &.active {
      display: block;
    }
  }

  .menu-item {
    border-top: 1px solid _palette(border);
    display: block;
    margin: 0;

    &:not(.menu-button):last-child {
      border-bottom: 1px solid _palette(border);
    }

    a {
      &:not(.button),
      &.button-icon {
        padding: 1em 0;
      }

      &:not(.button-icon) {
        display: block;
      }
    }

    &.has-children > a {
      margin-right: 30px;
    }

    .menu-item {
      &:first-child {
        border-top: 0;
      }

      &:last-child {
        border-bottom: 0;
      }
    }

    .submenu-toggle {
      background: 0;
      border: 0;
      border-radius: 0;
      color: _palette(meta);
      display: block;
      height: 48px;
      padding: 0;
      position: absolute;
      right: 0;
      top: 0;
      width: 30px;
  
      &.active .icon-angle-right {
        -webkit-transform: rotate(135deg);
        transform: rotate(135deg);
      }
    }
  }

  .menu-button {
    & > .button:not(.button-icon) {
      margin-bottom: 1em;
      margin-top: 1em;
    }
 
    & + .menu-button {
      border-top: 0;
    }
  }
}

</style>
<template>
<header id="masthead" class="site-header outer">
   <div class="inner">
      <div class="site-header-inside">
         <div class="site-branding">
            <p class="site-logo"><a v-bind:href="branding.parentUrl"><img src="https://covid19forecasthub.org/images/forecast-hub-logo_DARKBLUE.png" v-bind:alt="branding.title" /></a></p>
         </div>
         <!-- .site-branding -->
         <nav id="main-navigation" class="site-navigation" aria-label="Main Navigation">
            <div class="site-nav-inside">
               <button id="menu-close" class="menu-toggle"><span class="screen-reader-text">Open Menu</span><span class="icon-close" aria-hidden="true"></span></button>
               <ul class="menu">
                  <li class="menu-item current">
                     <a class="" v-bind:href="branding.parentUrl">
                     Home
                     </a>
                  </li>
                  <li class="menu-item">
                     <a class="" v-bind:href="branding.dataUrl">
                     Data
                     </a>
                  </li>
                  <li class="menu-item">
                     <a class="" v-bind:href="branding.communityUrl">
                     Community
                     </a>
                  </li>
                  <li class="menu-item">
                     <a class="" v-bind:href="branding.aboutUrl">
                     About
                     </a>
                  </li>
                  <li class="menu-item menu-button">
                     <a class="button" href="https://github.com/reichlab/covid19-forecast-hub" target="_blank" rel="noopener">GitHub</a>          
                  </li>
               </ul>
            </div>
            <!-- .site-nav-inside -->
         </nav>
         <!-- .site-navigation -->
      </div>
      <!-- .site-header-inside -->
   </div>
   <!-- .inner -->
</header>
<!-- .site-header -->
 </template>

<script>
import { mapGetters, mapActions } from 'vuex'

export default {
  computed: {
    ...mapGetters(['branding'])
  },
  methods: {
    ...mapActions('intro', ['moveIntroStart'])
  }
}
</script>
