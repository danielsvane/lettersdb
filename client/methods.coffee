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

@findSmallestDifference = (vectors, letter) ->
  smallestDifference = 0
  letter = letter.replace RegExp("(\r\n|\n|\r)", "gm"), ""
  letter = letter.replace RegExp(" ", "g"), ""
  id = 0
  name = ""
  for symbol in Symbols.find({name: letter}).fetch()
    if vectors.length is symbol.lines.length
      difference = 0
      divisor = 0
      for line, i in symbol.lines
        if line.averagedVectors and vectors[i]
          difference += getDifference(line.averagedVectors, vectors[i].normalizedVectors) # Get difference in line vectors
          difference += Vector.sub(line.startVector, vectors[i].startVector).mag() # Get difference in line start coord
          divisor++
      # if symbol.lines.length > 0
      #   difference = difference/(divisor*2)
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
  savedSymbol = Symbols.findOne
    _id: Session.get("currentLetterId")
  currentSymbol = Symbols.findOne(Session.get("currentSymbol"))

  smallestDifference = findSmallestDifference(currentSymbol.lines, name)
  # If difference in letters is less than a threshhold
  if 0 < smallestDifference.difference < 150
    mergeLetter smallestDifference.id
  # Otherwise save the drawn letter as a variation
  else
    saveNewLetter name

  Session.set("savingLetter", false)

@mergeLetter = (id) ->
  currentSymbol = Symbols.findOne(Session.get("currentSymbol"))
  closestSymbol = Symbols.findOne id
  # Merge the drawn vectors with the saved ones
  if closestSymbol and closestSymbol.lines
    newLines = []
    for i in [0..closestSymbol.lines.length-1]
      savedVectors = 0
      if closestSymbol.lines[i] and currentSymbol.lines[i]
        savedVectors = closestSymbol.lines[i].averagedVectors
        drawnVectors = currentSymbol.lines[i].normalizedVectors
        averagedVectors = averageVectors(savedVectors, drawnVectors, closestSymbol.weight)
        newLines.push
          startVector: averageVectors([closestSymbol.lines[i].startVector], [currentSymbol.lines[i].startVector], closestSymbol.weight)[0]
          averagedVectors: averagedVectors

    Symbols.update closestSymbol._id,
      $set:
        lines: newLines
      $inc:
        weight: 1

  Session.set "currentSymbol", Symbols.insert
    lines: []
  Session.set "currentLetter", closestSymbol.name
  Session.set "currentLetterId", closestSymbol._id

@saveNewLetter = (name) ->
  currentSymbol = Symbols.findOne(Session.get("currentSymbol"))
  newLines = []
  for i in [0..currentSymbol.lines.length-1]
    newLines.push
      startVector: currentSymbol.lines[i].startVector
      averagedVectors: currentSymbol.lines[i].normalizedVectors
  symbol = Symbols.insert
    name: name
    lines: newLines
    weight: 1

  Settings.update Session.get("settingsId"),
    $addToSet:
      letters: name

  Session.set "currentSymbol", Symbols.insert
    lines: []
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