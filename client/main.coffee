@prevX = 0
@prevY = 0

@parts = []

Meteor.startup ->

  GAnalytics.pageview()

  Session.set("currentLetter", "new")

  Meteor.subscribe "settings", ->
    settings = Settings.find().fetch()[0]
    Session.set("settingsId", settings._id)
  Meteor.subscribe "symbols", ->
    symbol = Symbols.findOne
      _id: Session.get("currentLetterId")
  Meteor.subscribe "lines"

  $("#svg").mousedown onMouseDown

  Session.set "currentSymbol", Symbols.insert {}

lineToVectors = (line) ->
  vectors = []
  for i in [0..line.length-2]
    vectors.push new Vector(line[i+1][0]-line[i][0], line[i+1][1]-line[i][1])
  vectors

totalDrawnLines = 0

onMouseUp = (e) ->
  vectors = lineToVectors @parts
  normalizedVectors = normalizeVectors(vectors)
  line = Lines.findOne
    symbol: Session.get("currentSymbol")
    index: totalDrawnLines-1
  Lines.update line._id,
    $set:
      normalizedVectors: normalizedVectors

  $("#svg").unbind "mousemove"
  $("#svg").unbind "mouseup"

onMouseDown = (e) ->
  @scale = 500/$("#svg").width() # Find out how much SVG has been scaled for correct drawing coordinates
  @parts = []
  @prevX = (e.pageX-@.getBoundingClientRect().left-window.scrollX)*@scale
  @prevY = (e.pageY-@.getBoundingClientRect().top-window.scrollY)*@scale

  @startVector = new Vector(@prevX, @prevY)

  @parts.push [@prevX, @prevY]

  @line = Lines.insert
    symbol: Session.get("currentSymbol")
    index: totalDrawnLines
    startVector: @startVector
    drawnVectors: []
    normalizedVectors: []

  totalDrawnLines++

  $("#svg").mousemove (e) ->
    x = (e.pageX-@.getBoundingClientRect().left-window.scrollX)*@scale
    y = (e.pageY-@.getBoundingClientRect().top-window.scrollY)*@scale

    Lines.update @line,
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
    clearLines()

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