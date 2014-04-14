if Meteor.isClient

  Template.menu.letters = ->
    pipeline = [{
      $match:
        name:
          $exists: true
    }, {
      $sort:
        weight: 1
    }, {
      $group:
        _id: "$name"
        data:
          $push:
            id:
              "$_id"
            weight:
              "$weight"
    }, {
      $sort:
        _id: 1
    }]

    Symbols.aggregate pipeline, (err, res) ->
      #letters = Symbols.find
      console.log res
      Session.set("letters", res)

    Session.get("letters")

  Template.svg.drawnLines = ->
    currentSymbol = Symbols.findOne Session.get("currentSymbol")
    if currentSymbol and currentSymbol.lines[0]
      currentSymbol.lines[0].drawnVectors

  Template.svg.averagedLines = ->
    lines = []
    symbol = Symbols.findOne
      _id: Session.get("currentLetterId")
    if symbol
      for line in symbol.lines
        l =
          averagedVectors: lineToSvg(line.startVector, line.averagedVectors)
        lines.push l

    lines

  Template.svg.lines = ->
    lines = []
    symbol = Symbols.findOne Session.get("currentSymbol")
    if symbol
      for line in symbol.lines
        l =
          normalizedVectors: lineToSvg(line.startVector, line.normalizedVectors)
          drawnVectors: line.drawnVectors
          #averagedVectors: lineToSvg(line.startVector, line.normalizedVectors)
        lines.push l

    lines
