@Symbols = new Meteor.Collection("symbols")

Symbols.allow
  insert: (userId, doc) ->
    true
  update: ->
    true