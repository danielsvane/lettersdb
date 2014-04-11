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

@unitVectors = (vectors) ->
  unitVectors = []
  tempVectors = []

  console.log "Vectors:", vectors

  length = 0
  longestMag = 0
  for v, i in vectors
    tempVectors.push new Vector().copy(v)
    vector = tempVectors[i]
    if vector.mag() > longestMag
      longestMag = vector.mag()
    length += vector.mag()

  console.log "Temp vectors:", tempVectors

  for v in tempVectors
    vector = v.norm().scale(v.mag()/longestMag)
    vector.add new Vector(0.5, 0.5)
    unitVectors.push vector.x, vector.y

  console.log "Unit vectors:", unitVectors.sort()

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

  console.log "Training set:", trainingSet

  console.log "Started training..."

  console.log "Training info:", net.train(trainingSet)
  output = net.run(unitVectors(vectors))
  console.log output