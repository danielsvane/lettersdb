@Alphabets = new Meteor.Collection "alphabets",
  schema:
    name:
      type: String
      label: "Name"
    public:
      type: Boolean
      label: "Public"
    user:
      type: String
      autoValue: ->
        @.userId

Alphabets.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
    true      