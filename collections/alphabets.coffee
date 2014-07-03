@Alphabets = new Meteor.Collection "alphabets",
  schema:
    name:
      type: String
      label: "Name"