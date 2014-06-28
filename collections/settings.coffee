@Settings = new Meteor.Collection("settings")

Settings.allow
  update: ->
    true