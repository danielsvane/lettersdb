@prevX = 0
@prevY = 0

@parts = []

Meteor.startup ->

  Session.set("currentLetter", "new")

  Meteor.subscribe "settings", ->
    settings = Settings.find().fetch()[0]
    Session.set("settingsId", settings._id)
  Meteor.subscribe "symbols", ->
    symbol = Symbols.findOne
      _id: Session.get("currentLetterId")

  $("#svg").mousedown onMouseDown

  Session.set "currentSymbol", Symbols.insert
    lines: []

lineToVectors = (line) ->
  vectors = []
  for i in [0..line.length-2]
    vectors.push new Vector(line[i+1][0]-line[i][0], line[i+1][1]-line[i][1])
  vectors

totalDrawnLines = 0

onMouseUp = (e) ->
  vectors = lineToVectors @parts
  normalizedVectors = normalizeVectors(vectors)

  Meteor.call("updateNormalizedVectors", Session.get("currentSymbol"), totalDrawnLines-1, normalizedVectors)

  #$("#svg").unbind "mousedown"
  $("#svg").unbind "mousemove"
  $("#svg").unbind "mouseup"
  #zoomMode()

onMouseDown = (e) ->
  @startVector = new Vector(e.pageX-@.offsetLeft, e.pageY-@.offsetTop)

  @parts = []
  @prevX = e.pageX-@.offsetLeft
  @prevY = e.pageY-@.offsetTop
  @parts.push [@prevX, @prevY]

  Symbols.update Session.get("currentSymbol"),
    $push:
      lines:
        index: totalDrawnLines
        startVector: @startVector
        drawnVectors: []
        normalizedVectors: []

  totalDrawnLines++

  $("#svg").mousemove (e) ->
    x = e.pageX-@.offsetLeft
    y = e.pageY-@.offsetTop

    Meteor.call("updateDrawnVectors", Session.get("currentSymbol"), totalDrawnLines-1, @prevX, @prevY, x, y)

    @prevX = x
    @prevY = y
    @parts.push [@prevX, @prevY]

    #currentSymbol = Symbols.findOne Session.get("currentSymbol")
    #console.log currentSymbol.lines[0].normalizedVectors[5]

  $("#svg").mouseup onMouseUp

Template.menu.averagedVectors = ->
  symbol = Symbols.findOne
    name: "a"
  if symbol
    symbol.normalizedVectors.length

  else
    "0"

Template.menu.drawnLineLength = ->
  Session.get("drawnLineLength") or "0"



Template.menu.selected = (letter) ->
  if letter is Session.get("currentLetterId")
    "selected"
  else
    ""

Template.menu.lines = ->
  lines = []
  symbol = Symbols.findOne(Session.get("currentSymbol"))
  if symbol
    for line, i in symbol.lines
      l =
        index: i
        normalizedVectors: line.normalizedVectors.length
        drawnVectors: line.drawnVectors.length
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

Template.svg.drawnLines = ->
  currentSymbol = Symbols.findOne Session.get("currentSymbol")
  if currentSymbol and currentSymbol.lines[0]
    currentSymbol.lines[0].drawnVectors


lineToSvg = (startVector, vectors) ->
  counterVector = new Vector().copy(startVector)
  returnVectors = []
  for v in vectors
    line =
      x1: Math.round(counterVector.x)
      y1: Math.round(counterVector.y)

    counterVector.add v

    line.x2 = Math.round(counterVector.x)
    line.y2 = Math.round(counterVector.y)

    returnVectors.push line
  returnVectors

# Template.svg.averagedLines = ->
#   vectors = []
#   savedSymbol = Symbols.findOne
#     name: Session.get("currentLetter")

#   if savedSymbol and savedSymbol.lines[0]
#     startVector = savedSymbol.lines[0].startVector
#     counterVector = new Vector().copy(startVector)

#     for v in savedSymbol.normalizedVectors
#       line =
#         x1: Math.round(counterVector.x)
#         y1: Math.round(counterVector.y)

#       counterVector.add v

#       line.x2 = Math.round(counterVector.x)
#       line.y2 = Math.round(counterVector.y)

#       vectors.push line

#   vectors

Template.new_letter_modal.savingLetter = ->
  Session.get("savingLetter")

Template.svg.normalizedLines = ->
  vectors = []
  savedSymbol = Symbols.findOne Session.get("currentSymbol")

  if savedSymbol && savedSymbol.lines[totalDrawnLines-1] && savedSymbol.lines[totalDrawnLines-1].normalizedVectors
    startVector = savedSymbol.lines[totalDrawnLines-1].startVector
    counterVector = new Vector().copy(startVector)
    vectors = lineToSvg(startVector, savedSymbol.lines[totalDrawnLines-1].normalizedVectors)

  vectors

drawMode = ->
  #svgPanZoom.resetZoom()
  svgPanZoom.disablePan()
  svgPanZoom.disableZoom()
  svgPanZoom.disableDrag()
  $("#svg").mousedown onMouseDown

zoomMode = ->
  svgPanZoom.init()

Template.new_letter_modal.events
  "click #close": ->
    Session.set("savingLetter", false)
  "click #save": ->
    saveLetter $("#new-letter").val()

Template.menu.events
  "click #save-symbol": ->
    if Session.get("currentLetter") is "new"
      Session.set("savingLetter", true)
    else
      saveLetter Session.get("currentLetter")
    
  "click #clear-symbol": ->
    Session.set "currentSymbol", Symbols.insert
      lines: []

  "change #variations": (e) ->
    Session.set "currentLetterId", $(e.target).val()

  "change #letters": (e) ->
    name = $(e.target).val()
    if name is "new"
      Session.set "currentLetterId", null
      Session.set "currentLetter", "new"
    else
      symbol = Symbols.findOne
        name: $(e.target).val()
      , 
        sort:
          weight: -1
      Session.set "currentLetterId", symbol._id
      Session.set "currentLetter", symbol.name

  "click #search-symbol": ->
    vectors = Symbols.findOne(Session.get("currentSymbol")).lines[0].normalizedVectors
    train(vectors)