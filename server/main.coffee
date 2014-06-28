Meteor.publish "symbols", ->
  Symbols.find()

Meteor.publish "settings", ->
  Settings.find()

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
  # Anything involving the $ (needed to update nested arrays) operator in mongodb only works on the server
  updateNormalizedVectors: (currentSymbol, index, normalizedVectors) ->
    Symbols.update
      _id: currentSymbol
      "lines.index": index
    ,
      $set:
        "lines.$.normalizedVectors": normalizedVectors

  updateDrawnVectors: (currentSymbol, index, x1, y1, x2, y2) ->
    Symbols.update
      _id: currentSymbol
      "lines.index": index
    ,
      $push:
        "lines.$.drawnVectors":
          x1: x1
          y1: y1
          x2: x2
          y2: y2