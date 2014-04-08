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
        name: Session.get("currentLetter") or "a"

    $("#svg").mousedown onMouseDown

  normalizeVectors = (vectors) ->
    divisions = 50

    # Find the total length of drawn vectors
    length = 0
    for v in vectors
      length += v.mag()

    averageLength = length/divisions # 10 divisions
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

  onMouseUp = (e) ->
    vectors = lineToVectors @parts
    normalizedVectors = normalizeVectors(vectors)

    Symbols.update Session.get("currentSymbol"),
      $set:
        normalizedVectors: normalizedVectors

    zoomMode()

  onMouseDown = (e) ->
    @startVector = new Vector(e.pageX-@.offsetLeft, e.pageY-@.offsetTop)

    @parts = []
    @prevX = e.pageX-@.offsetLeft
    @prevY = e.pageY-@.offsetTop
    @parts.push [@prevX, @prevY]

    Session.set "currentSymbol", Symbols.insert
      startVector: @startVector
      drawnVectors: []

    $("#svg").mousemove (e) ->
      x = e.pageX-@.offsetLeft
      y = e.pageY-@.offsetTop

      Symbols.update Session.get("currentSymbol"),
        $push:
          drawnVectors:
            x1: @prevX
            y1: @prevY
            x2: x
            y2: y

      @prevX = x
      @prevY = y
      @parts.push [@prevX, @prevY]

    $("#svg").mouseup onMouseUp

  Template.info_wrapper.drawnVectors = ->
    symbol = Symbols.findOne(Session.get("currentSymbol"))
    if symbol
      symbol.drawnVectors.length

    else
      "0"

  Template.info_wrapper.normalizedVectors = ->
    symbol = Symbols.findOne(Session.get("currentSymbol"))
    if symbol and symbol.normalizedVectors
      symbol.normalizedVectors.length

    else
      "0"

  Template.info_wrapper.averagedVectors = ->
    symbol = Symbols.findOne
      name: "a"
    if symbol
      symbol.normalizedVectors.length

    else
      "0"

  Template.info_wrapper.drawnLineLength = ->
    Session.get("drawnLineLength") or "0"

  Template.info_wrapper.letters = ->
    Symbols.find
      name:
        $exists: true

  Template.info_wrapper.selected = (letter) ->
    console.log letter, Session.get("currentLetter")
    if letter is Session.get("currentLetter")
      console.log "selected"
      "selected"
    else
      ""

  Template.menu_wrapper.drawnLines = ->
    currentSymbol = Symbols.findOne Session.get("currentSymbol")
    if currentSymbol
      currentSymbol.drawnVectors

  Template.menu_wrapper.averagedLines = ->
    vectors = []
    savedSymbol = Symbols.findOne
      name: Session.get("currentLetter")

    if savedSymbol
      startVector = savedSymbol.startVector
      counterVector = new Vector().copy(startVector)

      for v in savedSymbol.normalizedVectors
        line =
          x1: Math.round(counterVector.x)
          y1: Math.round(counterVector.y)

        counterVector.add v

        line.x2 = Math.round(counterVector.x)
        line.y2 = Math.round(counterVector.y)

        vectors.push line

    vectors

  Template.new_letter_modal.savingLetter = ->
    Session.get("savingLetter")

  Template.menu_wrapper.normalizedLines = ->
    vectors = []
    savedSymbol = Symbols.findOne Session.get("currentSymbol")

    if savedSymbol && savedSymbol.normalizedVectors
      startVector = savedSymbol.startVector
      counterVector = new Vector().copy(startVector)

      console.log "Total normalized vectors created:", savedSymbol.normalizedVectors.length
      for v in savedSymbol.normalizedVectors
        line =
          x1: counterVector.x
          y1: counterVector.y

        #console.log "Current normalized vector:", savedSymbol.normalizedVectors

        counterVector.add v

        #console.log "Dimensions of last added normalized vector:", counterVector.x, counterVector.y

        line.x2 = counterVector.x
        line.y2 = counterVector.y

        vectors.push line

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
    $("#svg").unbind "mousedown"
    $("#svg").unbind "mousemove"
    $("#svg").unbind "mouseup"

  saveLetter = ->
    # Check to see if symbol already exists
    savedSymbol = Symbols.findOne
      name: Session.get("currentLetter")
    drawnSymbol = Symbols.findOne(Session.get("currentSymbol"))
    # If it exists, average the two sets of normalized vectors
    if savedSymbol
      averagedVectors = averageVectors(savedSymbol.normalizedVectors, drawnSymbol.normalizedVectors, savedSymbol.weight)
      Symbols.update savedSymbol._id,
        $set:
          normalizedVectors: averagedVectors
          startVector: averageVectors([savedSymbol.startVector], [drawnSymbol.startVector], savedSymbol.weight)[0]
        $inc:
          weight: 1
    else
      Symbols.insert
        name: $("#new-letter").val()
        normalizedVectors: drawnSymbol.normalizedVectors
        startVector: drawnSymbol.startVector
        weight: 1
    Session.set("savingLetter", false)

  Template.new_letter_modal.events
    "click #close": ->
      Session.set("savingLetter", false)
    "click #save": ->
      Session.set("currentLetter", $("#new-letter").val())
      saveLetter()
      drawMode()
      Session.set("currentSymbol", null)

  Template.info_wrapper.events
    "click #save-symbol": ->
      if Session.get("currentLetter") is "new"
        Session.set("savingLetter", true)
      else
        saveLetter()
      
    "click #clear-symbol": ->
      Session.set("currentSymbol", null)
      drawMode()

    "change #letters": (e) ->
      console.log $(e.target).val()
      Session.set "currentLetter", $(e.target).val()