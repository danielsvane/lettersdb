AutoForm.hooks
  insertAlphabetForm:
    onSuccess: (err, res) ->
      Session.set "currentAlphabet", res
      $('#new_alphabet_modal').modal('hide')

  editAlphabetForm:
    onSuccess: ->
      $('#edit_alphabet_modal').modal('hide')

  removeAlphabetForm:
    before:
      remove: (docId) ->
    onSuccess: ->
      Session.set "currentAlphabet"

Template.admin.alphabets = ->
  Alphabets.find()

Template.admin.showNewModal = ->
  Session.get "showNewModal"

Template.admin.showEditModal = ->
  Session.get "showEditModal"

Template.admin.selected = ->
  if @._id is Session.get("currentAlphabet") then "selected" else ""

UI.registerHelper "currentAlphabet", ->
  if not Session.get("currentAlphabet")
    Session.set("currentAlphabet", Alphabets.findOne())
  Alphabets.findOne(Session.get("currentAlphabet"))

Template.new_alphabet_modal.rendered = ->
  $("#new_alphabet_modal").modal("show")
  $("#new_alphabet_modal").on "hidden.bs.modal", (e) ->
    Session.set "showNewModal", false

Template.edit_alphabet_modal.rendered = ->
  $("#edit_alphabet_modal").modal("show")
  $("#edit_alphabet_modal").on "hidden.bs.modal", (e) ->
    Session.set "showEditModal", false
  
Template.admin.events
  "click #create-alphabet": ->
    Session.set "showNewModal", true
  "click #edit-alphabet": ->
    Session.set "showEditModal", true
  "change #select-alphabet": (event, template) ->
    Session.set "currentAlphabet", event.currentTarget.value