Router.configure
  layoutTemplate: "layout"
  load: ->
    GAnalytics.pageview()

Router.map ->
  @.route "home",
    path: "/"
  @.route "admin"