AutoForm.hooks
  insertAlphabetForm:
    onSuccess: (err, res) ->
      Session.set "currentAlphabet", res
      $('#new_alphabet_modal').modal('hide')

  editAlphabetForm:
    onSuccess: ->
      $('#edit_alphabet_modal').modal('hide')

Template.alphabets.alphabets = ->
  Alphabets.find()

Template.alphabets.showNewModal = ->
  Session.get "showNewModal"

Template.alphabets.showEditModal = ->
  Session.get "showEditModal"

Template.alphabets.showRemoveModal = ->
  Session.get "showRemoveModal"

Template.alphabets.selected = ->
  if @._id is Session.get("currentAlphabet") then "selected" else ""

UI.registerHelper "currentAlphabet", ->
  alphabet = Alphabets.findOne()
  if not Session.get("currentAlphabet") and alphabet
    Session.set("currentAlphabet", alphabet._id)
  Alphabets.findOne(Session.get("currentAlphabet"))

Template.new_alphabet_modal.rendered = ->
  $("#new_alphabet_modal").modal("show")
  $("#new_alphabet_modal").on "hidden.bs.modal", (e) ->
    Session.set "showNewModal", false

Template.edit_alphabet_modal.rendered = ->
  $("#edit_alphabet_modal").modal("show")
  $("#edit_alphabet_modal").on "hidden.bs.modal", (e) ->
    Session.set "showEditModal", false

Template.remove_alphabet_modal.rendered = ->
  $("#remove_alphabet_modal").modal("show")
  $("#remove_alphabet_modal").on "hidden.bs.modal", (e) ->
    Session.set "showRemoveModal", false

Template.alphabets.events
  "click #create-alphabet": ->
    Session.set "showNewModal", true
  "click #edit-alphabet": ->
    Session.set "showEditModal", true
  "click #remove-alphabet": ->
    Session.set "showRemoveModal", true
  "change #select-alphabet": (event, template) ->
    Session.set "currentAlphabet", event.currentTarget.value

Template.remove_alphabet_modal.events
  "click #remove": ->
    $('#remove_alphabet_modal').modal('hide')
    Alphabets.remove Session.get("currentAlphabet")
    Session.set "currentAlphabet"