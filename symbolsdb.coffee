@Symbols = new Meteor.Collection("symbols")

if Meteor.isServer
  Meteor.publish "symbols", ->
    Symbols.find()

if Meteor.isClient

  @prevX = 0
  @prevY = 0

  @parts = []

  Meteor.startup ->

    Session.set("currentLetter", "new")

    Meteor.subscribe "symbols", ->
      symbol = Symbols.findOne
        _id: Session.get("currentLetterId")

    $("#svg").mousedown onMouseDown

    Session.set "currentSymbol", Symbols.insert
      lines: []

  normalizeVectors = (vectors) ->
    divisions = 50

    # Find the total length of drawn vectors
    length = 0
    for v in vectors
      length += v.mag()

    averageLength = length/divisions
    normalizedVectors = []
    sum = 0

    # Keep track of current drawn vector
    v = 0
    # For each division
    for i in [0..divisions-1]
      normalizedVector = new Vector

      sum = vectors[v].mag()
      if sum >= averageLength
        averageVector = vectors[v].clone().norm().scale(averageLength)
        normalizedVector.add averageVector
        vectors[v].sub averageVector
      if sum < averageLength
        while sum < averageLength
          # Add drawn vector to normalized vector
          normalizedVector.add vectors[v++]
          if vectors[v]
            sum += vectors[v].mag()
          else
            sum = averageLength
        if vectors[v]
          overshotVector = vectors[v].clone().norm().scale(averageLength-(sum-vectors[v].mag()))
          normalizedVector.add overshotVector
          vectors[v].sub overshotVector

      normalizedVectors.push normalizedVector.clone()
    normalizedVectors

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

  # Finds the average of two sets of vectors, with weight applied to first set
  averageVectors = (vectors1, vectors2, weight = 1) ->
    averagedVectors = []
    for i in [0..vectors1.length-1]
      v1 = new Vector().copy(vectors1[i])
      v2 = new Vector().copy(vectors2[i])
      v = v1.scale(weight).add(v2)
      v.scale(1/(1+weight))
      averagedVectors.push v
    averagedVectors

  drawMode = ->
    #svgPanZoom.resetZoom()
    svgPanZoom.disablePan()
    svgPanZoom.disableZoom()
    svgPanZoom.disableDrag()
    $("#svg").mousedown onMouseDown

  zoomMode = ->
    svgPanZoom.init()

  saveLetter = ->
    # Check to see if symbol already exists
    savedSymbol = Symbols.findOne
      _id: Session.get("currentLetterId")
    currentSymbol = Symbols.findOne(Session.get("currentSymbol"))
    # If it exists, average the two sets of normalized vectors
    # if savedSymbol
    #   newLines = []
    #   for i in [0..savedSymbol.lines.length-1]
    #     savedVectors = 0
    #     if savedSymbol.lines[i] and currentSymbol.lines[i]
    #       savedVectors = savedSymbol.lines[i].averagedVectors
    #       drawnVectors = currentSymbol.lines[i].normalizedVectors
    #       averagedVectors = averageVectors(savedVectors, drawnVectors, savedSymbol.weight)
    #       newLines.push
    #         startVector: averageVectors([savedSymbol.lines[i].startVector], [currentSymbol.lines[i].startVector], savedSymbol.weight)[0]
    #         averagedVectors: averagedVectors

    #   Symbols.update savedSymbol._id,
    #     $set:
    #       lines: newLines
    #     $inc:
    #       weight: 1
    #   Symbols.insert
    #     name: Session.get("currentLetter")

    if savedSymbol
      difference = getDifference(savedSymbol.averagedVectors, vectors2)

    newLines = []
    for i in [0..currentSymbol.lines.length-1]
      newLines.push
        startVector: currentSymbol.lines[i].startVector
        averagedVectors: currentSymbol.lines[i].normalizedVectors
    symbol = Symbols.insert
      name: $("#new-letter").val()
      lines: newLines
      weight: 1

    Session.set "currentSymbol", Symbols.insert
      lines: []

    Session.set "currentLetterId", symbol
    Session.set("savingLetter", false)

  Template.new_letter_modal.events
    "click #close": ->
      Session.set("savingLetter", false)
    "click #save": ->
      #Session.set("currentLetter", $("#new-letter").val())

      saveLetter()

  Template.menu.events
    "click #save-symbol": ->
      #if Session.get("currentLetter") is "new"
      Session.set("savingLetter", true)
      # else
      #   saveLetter()
      
    "click #clear-symbol": ->
      Session.set "currentSymbol", Symbols.insert
        lines: []
      #drawMode()

    "change #letters": (e) ->
      Session.set "currentLetter", $(e.target).text()
      Session.set "currentLetterId", $(e.target).val()

    "click #search-symbol": ->
      vectors = Symbols.findOne(Session.get("currentSymbol")).lines[0].normalizedVectors
      train(vectors)