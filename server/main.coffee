Meteor.publish "symbols", ->
  Symbols.find()

Meteor.publish "lines", ->
  Lines.find()

Meteor.publish "settings", ->
  Settings.find()

Meteor.publish "alphabets", ->
  Alphabets.find()

# Remove a clients drawing symbol when disconnecting
Meteor.onConnection (connection) ->
  connection.onClose ->
    console.log "Closing connection with id: #{connection.id}"
    symbol = Symbols.findOne
      sessionId: connection.id
    if symbol
      console.log "Removing symbol and lines with id: #{symbol._id}"
      Lines.remove
        symbol: symbol._id
      Symbols.remove symbol._id

# Create settings doc if it doesnt exist
if !Settings.find().count()
  settings = Settings.insert
    letters: []
  console.log "Created settings with id:", settings
else
  settings = Settings.find().fetch()[0]
  console.log "Settings with id:", settings._id, "already saved"
  console.log settings.letters

Meteor.methods
  getSessionId: ->
    @.connection.id