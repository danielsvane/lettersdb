Template.menu.letters = ->
  settings = Settings.findOne(Session.get("settingsId"))
  if settings
    settings.letters.sort()
  else
    []

Template.menu.letterSelected = (letter) ->
  if Session.get("currentLetter") is letter
    "selected"
  else 
    ""

Template.menu.showVariations = ->
  Session.get("currentLetter") isnt "new"

Template.menu.showButtons = ->
  line = Lines.findOne({symbol:Session.get("currentSymbol")})
  if line && line.normalizedVectors
    line.normalizedVectors[0]
  else
    false

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

Template.new_letter_modal.savingLetter = ->
  Session.get("savingLetter")

Template.svg.savedLines = ->
  Lines.find
    symbol: Session.get("currentLetterId")

Template.svg.averagedVectors = ->
  line = Lines.findOne(@._id)
  if line && line.averagedVectors
    lineToSvg(line.startVector, line.averagedVectors)
  else
    []

Template.svg.drawnLines = ->
  Lines.find
    symbol: Session.get("currentSymbol")

Template.svg.normalizedVectors = ->
  line = Lines.findOne(@._id)
  if line
    lineToSvg(line.startVector, line.normalizedVectors)
  else
    []

Template.svg.drawnVectors = ->
  line = Lines.findOne(@._id)
  if line then line.drawnVectors else []
