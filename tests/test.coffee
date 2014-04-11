assert = require("assert")

suite "Letters", ->

  test "can be saved", (done, server) ->
    server.eval ->
      Symbols.insert
        name: "a"
      docs = Symbols.find().fetch()
      emit "docs", docs

    server.once "docs", (docs) ->
      assert.equal docs.length, 1
      assert.equal docs[0].name, "a"
      done()

  test "can call global functions", (done, server) ->
    server.eval ->
      emit "msg", reallyWorks()
    server.once "msg", (msg) ->
      assert.equal msg, "really"
      done()
