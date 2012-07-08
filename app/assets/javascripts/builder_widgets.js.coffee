
    
$.widget 'ui.ContainerUI',
  options: {}
  _create: ->
  _init: ->
    @container = @options.container
    @parent = @options.parent
    @builder = @options.builder
    cc= @._createContainer()
    @element.append(cc)
    @builder._bindClickHandler()
    
  _createContainer: ->
    $inner = $("<div>")
    #$inner = $dc.find(".paramItem")
    # $dc.css("width",300).css("height",100).find(".paramItem").css("width",280).css("height",80)
    for child,i in @container.children
      childItem = @._createItemUI(child)
      $inner.append childItem
      if (i < @container.children.length-1)
        if @container instanceof queryStructure.AND then conjunction="and" else conjunction="or"
        $inner.append("<span class='"+conjunction+"'>"+conjunction+"</span>")
    return $inner.children()
      
  _createItemUI: (item) ->
    # we need a container outside of the param_group
    $result_container = $("<div>")
    $dc = @template('param_group')
    $result_container.append($dc)

    if item.children
      console.log "item has children",item.children
      $dc.addClass(if @container instanceof queryStructure.AND then "and" else "or")
      $dc.find(".paramItem").droppable(
        over: @._over
        out: @._out
        drop: @._drop
      )
      $itemUI = $dc.find('.paramItem')
      if item instanceof queryStructure.AND
        # if we have no children array for this item, then we must be a leaf node (an individual data_criteria)
        # $itemUI = @template('param_group')
        $itemUI.AndContainerUI(
          parent: @
          container: item
          builder: @builder
        )
      if item instanceof queryStructure.OR
        # if we have no children array for this item, then we must be a leaf node (an individual data_criteria)
        # $itemUI = @template('param_group')
        $itemUI.OrContainerUI(
          parent: @
          container: item
          builder: @builder
        )
      if !item instanceof queryStructure.AND && !item instanceof queryStructure.OR
        console.log("Error! - item is neither AND nor OR")
    else 
      console.log("=============================================== item has no children", @)
      data_criteria = @builder.data_criteria[item.id]
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $result_container.prepend("<span class='#{subset_operator.type} subset-operator'>#{subset_operator.title()}</span>")
      
      $itemUI = data_criteria.asHtml("data_criteria_logic")
      if (data_criteria.temporal_references?)
        items = data_criteria.temporalReferenceItems()
        for item in items
          $itemUI.append("<span class='#{item.conjunction} temporal-operator'>#{item.title}</span><span class='block-down-arrow'></span>")




      if (data_criteria.children_criteria?)
        items = data_criteria.childrenCriteriaItems()
      else
        # we dont have a nested measure clause, add the item to the bottom of the list
        # if (!elemParent.hasClass("paramItem"))
        elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last")
        elemParent.droppable(
          over:  @._over2
          tolerance:'pointer'
          greedy:true
          accept:'label.ui-draggable'
          out:  @._out
          drop: makeDropFn(@)
        )
        
        data_criteria.asHtml('data_criteria_logic').appendTo(elemParent)











      $itemUI.ItemUI(
        parent: @
        container: item
      )
      $dc.find(".paramItem").append($itemUI)
    return $result_container.children()
  template: (id,object={}) ->
      $("#bonnie_tmpl_#{id}").tmpl(object)
  _over: ->
    $(@).parents('.paramItem').removeClass('droppable')
    $(@).addClass('droppable')

  _out: ->
    $(@).removeClass('droppable')
  _drop: ->
    $(@).removeClass('droppable')


$.widget "ui.AndContainerUI", $.ui.ContainerUI,
  options: {}
  collectionType: ->
    "AND"

$.widget "ui.OrContainerUI", $.ui.ContainerUI,
  options: {}
  collectionType: ->
    "OR"

  
$.widget 'ui.ItemUI',
  options: {}
  _init: ->
    console.log("inside ui.ItemUI _init")
    @parent = @parent = @options.parent
    @container = @options.container
    # @dataCriteria = @options.dataCriteria
    @element.append("<div>")
  _createItem: ->
    # bonnie.template("data_criteria_logic",@dataCriteria)
    # @element.append("<p>#{container.id}</p>")

