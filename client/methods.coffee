@clearLines = ->
  for line in Lines.find({symbol:Session.get("currentSymbol")}).fetch()
    Lines.remove line._id

@lineToSvg = (startVector, vectors) ->
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

@reallyWorks = () ->
  "really"

@getDifference = (vectors1, vectors2) ->
  difference = 0
  for i in [0..vectors1.length-1]
    v1 = new Vector().copy(vectors1[i])
    v2 = new Vector().copy(vectors2[i])
    v = v1.sub v2
    difference += v.mag()
  difference

@findSmallestDifference = (lines, letter) ->
  smallestDifference = 0
  letter = letter.replace RegExp("(\r\n|\n|\r)", "gm"), ""
  letter = letter.replace RegExp(" ", "g"), ""
  id = 0
  name = ""
  for symbol in Symbols.find({name: letter}).fetch()
    # Find all lines for current symbol in iteration
    savedLines = Lines.find({symbol: symbol._id}).fetch()
    # If both symbols has same amount of lines it can be compared
    if lines.length is savedLines.length
      difference = 0
      # Calculate the difference in symbol lines
      for line, i in savedLines
        difference += getDifference(savedLines[i].averagedVectors, lines[i].normalizedVectors) # Get difference in line vectors
        difference += Vector.sub(savedLines[i].startVector, lines[i].startVector).mag() # Get difference in line start coord
      # Check if calculated difference is the smallest so far, and store it if it is
      if difference < smallestDifference or smallestDifference is 0
        if difference > 0
          smallestDifference = difference
          id = symbol._id
          name = symbol.name
  {
    difference: smallestDifference
    id: id
    name: name
  }

@unitVectors = (vectors) ->
  unitVectors = []
  tempVectors = []

  length = 0
  longestMag = 0
  for v, i in vectors
    tempVectors.push new Vector().copy(v)
    vector = tempVectors[i]
    if vector.mag() > longestMag
      longestMag = vector.mag()
    length += vector.mag()

  for v in tempVectors
    vector = v.norm().scale(v.mag()/longestMag)
    vector.add new Vector(0.5, 0.5)
    unitVectors.push vector.x, vector.y

  unitVectors

@train = (vectors) ->
  net = new brain.NeuralNetwork
    hiddenLayers: [20, 20]

  trainingSet = []

  letters = Symbols.find
    name:
      $exists: true
  for letter in letters.fetch()
    trainingObj =
      input: unitVectors(letter.lines[0].averagedVectors)
      output: {}
    trainingObj.output[letter.name] = 1
    trainingSet.push trainingObj

  console.log "Started training..."

  net.train(trainingSet)
  output = net.run(unitVectors(vectors))
  console.log output

@normalizeVectors = (vectors) ->
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

@saveLetter = (name) ->
  lines = Lines.find({symbol:Session.get("currentSymbol")}).fetch()

  smallestDifference = findSmallestDifference(lines, name)
  # If difference in letters is less than a threshhold
  if 0 < smallestDifference.difference < 150
    mergeLetter smallestDifference.id
  # Otherwise save the drawn letter as a variation
  else
    saveNewLetter name

  clearLines()
  Session.set("savingLetter", false)

@mergeLetter = (id) ->
  currentSymbol = Symbols.findOne(Session.get("currentSymbol"))
  savedSymbol = Symbols.findOne id

  drawnLines = Lines.find({symbol:Session.get("currentSymbol")}).fetch()
  savedLines = Lines.find({symbol:id}).fetch()

  # Merge the drawn vectors with the saved ones
  if drawnLines.length is savedLines.length
    newLines = []
    for line, i in savedLines
      savedVectors = savedLines[i].averagedVectors
      drawnVectors = drawnLines[i].normalizedVectors
      averagedVectors = averageVectors(savedVectors, drawnVectors, savedSymbol.weight)
      
      Lines.update line._id,
        $set:
          startVector: averageVectors([savedLines[i].startVector], [drawnLines[i].startVector], savedSymbol.weight)[0]
          averagedVectors: averagedVectors

    Symbols.update savedSymbol._id,
      $inc:
        weight: 1

  Session.set "currentLetter", savedSymbol.name
  Session.set "currentLetterId", savedSymbol._id

@saveNewLetter = (name) ->

  # Create a new symbol
  symbol = Symbols.insert
    name: name
    weight: 1

  lines = Lines.find
    symbol: Session.get("currentSymbol")

  # Go through all the drawn lines
  for line in lines.fetch()
    # Create new lines from normalized vectors
    Lines.insert
      symbol: symbol
      startVector: line.startVector
      averagedVectors: line.normalizedVectors

  # Add new letter to set
  Settings.update Session.get("settingsId"),
    $addToSet:
      letters: name

  Session.set "currentLetter", name
  Session.set "currentLetterId", symbol

# Finds the average of two sets of vectors, with weight applied to first set
@averageVectors = (vectors1, vectors2, weight = 1) ->
  averagedVectors = []
  for i in [0..vectors1.length-1]
    v1 = new Vector().copy(vectors1[i])
    v2 = new Vector().copy(vectors2[i])
    v = v1.scale(weight).add(v2)
    v.scale(1/(1+weight))
    averagedVectors.push v
  averagedVectors