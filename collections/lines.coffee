@Lines = new Meteor.Collection("lines")

Lines.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
    true