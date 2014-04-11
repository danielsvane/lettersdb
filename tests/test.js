// var assert;

// assert = require("assert");

// suite("Symbols", function() {
//   test("in the server", function(done, server) {
//     server["eval"](function() {
//       var docs;
//       Symbols.insert({
//         name: "hello"
//       });
//       docs = Symbols.find().fetch();
//       emit("docs", docs);
//     });
//     server.once("docs", function(docs) {
//       assert.equal(docs.length, 1);
//       done();
//     });
//   });
// });
