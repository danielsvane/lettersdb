if Meteor.isClient

  Template.menu.letters = ->
    settings = Settings.findOne(Session.get("settingsId"))
    if settings
      settings.letters
    else
      []

  Template.menu.letterSelected = (letter) ->
    if Session.get("currentLetter") is letter
      "selected"
    else 
      ""

  Template.menu.variationSelected = (id) ->
    if Session.get("currentLetterId") is id
      "selected"
    else 
      ""

  Template.menu.variations = ->
    Symbols.find
      name: Session.get("currentLetter")
    ,
      sort:
        weight: -1

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
