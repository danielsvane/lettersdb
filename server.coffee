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