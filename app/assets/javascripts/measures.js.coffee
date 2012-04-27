renderMeasureJson = (data) ->
  measure = data
  elemParent # TODO - needed for addParamItems scope?
  
  # TODO - Description
  addParamItems = (obj,elemParent,container) ->
    items = obj['and'] || obj['or']
    if $.isArray(items)
      conjunction = obj['and'] ? 'and' : 'or'
      
      # Add the grouping container
      if !container
        elemParent = $("#ph_tmpl_paramGroup").tmpl({}).appendTo(elemParent).find(".paramItem:last")
      # TODO - Transition to CS-style loop
      ###
      $.each(items, function(i, node) ->
        addParamItems(node,elemParent)
        if (i < items.length-1)
          $(elemParent).append("<span class='"+conjunction+"'>"+conjunction+"</span>");
      )
      ###
    else
      # We don't have a nested measure clause, add the item to the bottom of the list
      if (!elemParent.hasClass("paramItem"))
        elemParent = $("#ph_tmpl_paramGroup").tmpl({}).appendTo(elemParent).find(".paramItem:last")
      $("#ph_tmpl_paramItem").tmpl(obj).appendTo(elemParent)

  if (data.population)
    elemParent = $("#ph_tmpl_paramGroup").tmpl({}).appendTo("#eligibilityMeasureItems").find(".paramItem:last")
    addParamItems(data.population,elemParent,elemParent)
    elemParent.parent().addClass("population");

  if (!$.isEmptyObject(data.denominator))
    $("#eligibilityMeasureItems").append("<span class='and'>and</span>")
    addParamItems(data.denominator,$("#eligibilityMeasureItems"))

  if (data.numerator)
    addParamItems(data.numerator,$("#outcomeMeasureItems"))

  if 'exclusions' in data && !$.isEmptyObject(data['exclusions'])
    addParamItems(data.exclusions, $("#exclusionMeasureItems"))
    $("#exclusionMeasureItems").hide()
    $("#exclusionPanel").show()

# jquery-ui tabs
$ ->
  $('#tabs').tabs();
  $('#tabs').tabs("select", 0);  # select my measures tab