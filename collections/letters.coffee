@Letters = new Meteor.Collection "letters",
  schema:
    name:
      type: String
      label: "Name"
    alphabet:
      type: String

Letters.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
    true