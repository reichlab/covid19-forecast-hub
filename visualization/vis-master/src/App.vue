<style lang="scss">
$accent: #268bd2;

::selection {
  background: $accent;
  color: white;
}

::-moz-selection {
  background: $accent;
  color: white;
}

svg text::selection {
  fill: white;
}

body {
  background-color: white;
}

.tooltip {
  position: fixed;
  max-width: 250px;
  z-index: 100;
  box-shadow: 0px 0px 2px;
  border-radius: 1px;
  background-color: white;
  font-size: 11px;
  .bold {
    font-weight: bold;
  }
}

.section {
  padding: 30px 20px !important;

  &#panel-section {
    padding-bottom: 10px !important;
  }
}

// Hide logo div in please wait div
.pg-loading-logo-header {
  display: none;
}

.pg-loading-html {
  margin-top: 0 !important;
}
</style>

<template lang="pug">
div
  // Fixed position components
  intro

  // Main layout components
  navbar
  hr(style="margin:0px;")
  .section#panel-section
    #app.container
      panels
  hr(style="margin:0px;")
  foot
</template>

<script>
import Navbar from "./components/Navbar";
import Intro from "./components/Intro";
import Panels from "./components/Panels";
import Foot from "./components/Foot";

import brandLogo from "../brand-logo.png";

import { mapGetters, mapActions } from "vuex";

window.pw = require("./assets/please-wait.min.js");

export default {
  components: {
    Navbar,
    Intro,
    Panels,
    Foot
  },
  computed: {
    ...mapGetters(["branding"])
  },
  methods: {
    ...mapActions("weeks", ["backwardSelectedWeek", "forwardSelectedWeek"]),
    ...mapActions(["setBrandLogo"])
  },
  head: {
    title: function() {
      return {
        inner: this.branding.title,
        complement: this.branding.parent
      };
    },
    meta: function() {
      let metaItems = [
        { name: "application-name", content: this.branding.title },
        { name: "description", content: this.branding.description },
        // Twitter
        { name: "twitter:title", content: this.branding.title },
        { name: "twitter:description", content: this.branding.description },
        { name: "twitter:url", content: this.branding.appUrl },
        // Google+ / Schema.org
        { itemprop: "name", content: this.branding.title },
        { itemprop: "description", content: this.branding.description },
        // Open Graph
        { property: "og:title", content: this.branding.title },
        { property: "og:description", content: this.branding.description },
        { property: "og:url", content: this.branding.appUrl }
      ];

      // Check if imageUrl is specified in configuration
      if (this.branding.imageUrl) {
        return metaItems.concat([
          { itemprop: "image", content: this.branding.imageUrl },
          { property: "og:image", content: this.branding.imageUrl },
          { name: "twitter:image", content: this.branding.imageUrl }
        ]);
      } else {
        return metaItems;
      }
    }
  },
  ready() {
    this.setBrandLogo(brandLogo);
    window.loading_screen = window.pw.pleaseWait({
      logo: "",
      backgroundColor: "#268bd2",
      loadingHtml: `<div class="spinner">
                      <div class="bounce1"></div>
                      <div class="bounce2"></div>
                      <div class="bounce3"></div>
                    </div>`
    });

    window.addEventListener("keyup", evt => {
      if (evt.code === "ArrowRight") {
        this.forwardSelectedWeek();
      } else if (evt.code === "ArrowLeft") {
        this.backwardSelectedWeek();
      }
    });
  }
};
</script>
