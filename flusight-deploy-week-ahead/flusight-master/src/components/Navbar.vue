<style lang="scss" scoped>

@import url('https://fonts.googleapis.com/css?family=Open+Sans:800');
@import url('https://fonts.googleapis.com/css?family=Source+Sans+Pro:700');

.brand.title {
  display: flex;
  align-items: center;

  .title-text{
    font-family: 'Source Sans Pro';
    font-weight: bold;
    font-size: 20px;
  }

  a {
    display: flex;
    align-items: center;

    &:hover {
      border: none;
    }

    img {
      max-height: 40px;
    }
  }
}

.nav-container {
  box-shadow: 0px 5px 30px -20px;
  max-width: 100%;
}

@media screen and (min-width: 980px) {
  nav.nav {
    margin: 0 auto;
    max-width: 960px;
  }
}

@media screen and (min-width: 1180px) {
  nav.nav {
    max-width: 1200px;
  }
}

</style>

<template lang="pug">
.hero-head
  .container.nav-container
    nav.nav
      // Logo
      .nav-left
        span.nav-item.is-brand
          span.brand.title
            a.brand.title-text(v-bind:href="branding.parentUrl") {{ branding.title }}

      // Right side buttons
      #nav-menu.nav-right.nav-menu
        span.nav-item
          a.button.is-small(v-on:click="moveIntroStart")
            span.icon.is-small
              i.fa.fa-question
            span Help

          a.button.is-small(v-bind:href="branding.aboutUrl", target="_blank")
            span.icon.is-small
              i.fa.fa-info
            span About


          a.button.is-dark.is-small(
            v-bind:href="branding.sourceUrl"
            target="_blank"
          )
            span.icon.is-small
              i.fa.fa-github
            span Source
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
