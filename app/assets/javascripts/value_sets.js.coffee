# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
	codeField = $(".codeField:last").clone()
	console.log(codeField)
	$("#addCode").on "click", ->
		console.log(codeField)
		d= new Date()
		n= d.valueOf()
		console.log(n)
		codeField.attr("id", "value_set_#{n}")
		codeField.attr("value", "")
		$("#codes").append(codeField.clone())
		return false