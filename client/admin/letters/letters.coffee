AutoForm.hooks

  createLetterForm:
    before:
      insert: (doc) ->
        doc.alphabet = Session.get("currentAlphabet")
        doc
    onSuccess: (err, res) ->
      Session.set "currentLetter", res
      $('#create_letter_modal').modal('hide')

  updateLetterForm:
    onSuccess: ->
      $('#update_letter_modal').modal('hide')

Template.letters.letters = ->
  Letters.find
    alphabet: Session.get "currentAlphabet"

Template.letters.showCreateLetterModal = ->
  Session.get "showCreateLetterModal"

Template.letters.showUpdateLetterModal = ->
  Session.get "showUpdateLetterModal"

Template.letters.showRemoveLetterModal = ->
  Session.get "showRemoveLetterModal"

Template.letters.selected = ->
  if @._id is Session.get("currentLetter") then "selected" else ""

UI.registerHelper "currentLetter", ->
  letter = Letters.findOne()
  if not Session.get("currentLetter") and letter
    Session.set("currentLetter", letter._id)
  Letters.findOne(Session.get("currentLetter"))

Template.create_letter_modal.rendered = ->
  $("#create_letter_modal").modal("show")
  $("#create_letter_modal").on "hidden.bs.modal", (e) ->
    Session.set "showNewLetterModal", false

Template.update_letter_modal.rendered = ->
  $("#update_letter_modal").modal("show")
  $("#update_letter_modal").on "hidden.bs.modal", (e) ->
    Session.set "showEditLetterModal", false

Template.remove_letter_modal.rendered = ->
  $("#remove_letter_modal").modal("show")
  $("#remove_letter_modal").on "hidden.bs.modal", (e) ->
    Session.set "showRemoveLetterModal", false

Template.letters.events
  "click #create-letter": ->
    Session.set "showCreateLetterModal", true
  "click #edit-letter": ->
    Session.set "showUpdateLetterModal", true
  "click #remove-letter": ->
    Session.set "showRemoveLetterModal", true
  "change #select-letter": (event, template) ->
    Session.set "currentLetter", event.currentTarget.value

Template.remove_letter_modal.events
  "click #remove": ->
    $('#remove_letter_modal').modal('hide')
    Letters.remove Session.get("currentLetter")
    Session.set "currentLetter"