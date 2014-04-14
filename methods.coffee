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
  for v1, i in vectors1
    v2 = vectors2[i]
    v = v1.sub v2
    differene += v.mag()
  difference

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