# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
	codeField = $(".codeField:last").clone()
	$("#addCode").on "click", ->
		d= new Date()
		n= d.valueOf()
		codeField.attr("id", "value_set_#{n}")
		codeField.attr("value", "")
		$("#codes").append(codeField.clone())
		return false