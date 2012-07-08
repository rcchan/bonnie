
    
$.widget 'ui.ContainerUI',
  options: {}
  _create: ->
  _init: ->
    @container = @options.container
    @parent = @options.parent
    @builder = @options.builder
    cc= @._createContainer()
    @builder._bindClickHandler()
    
  _createContainer: ->
    $inner = $("<div>")
    console.log "@container = " ,@container
    for child,i in @container.children
      childItem = @._createItemUI(child)
      @element.append childItem
      if (i < @container.children.length-1)
        if @container instanceof queryStructure.AND then conjunction="and" else conjunction="or"
        @element.append("<span class='"+conjunction+"'>"+conjunction+"</span>")
    return $inner.children()
      
  _createItemUI: (item) ->
    # we need a container outside of the param_group
    $result_container = $("<div>")


    if item.children
      $dc = @template('param_group')
      $result_container.append($dc)
      $itemUI = $dc.find('.paramItem')
      console.log "item has children",item.children
      $dc.addClass(if @container instanceof queryStructure.AND then "and" else "or")
      $dc.find(".paramItem").droppable(
        over: @._over
        out: @._out
        drop: @._drop
      )
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
      
      @element.ItemUI(
        parent:@
        item:item
      )
      
      # I don't think we need to do this. ItemUI will add the elements directly to @element
      # $dc.find(".paramItem").append($itemUI)
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
    @parent = @options.parent
    @builder = @options.builder ? @parent.builder
    @item = @options.item
    @_createItem()
  _createItem: ->
    console.log "inside _createItem",@
    $result_container = $("<div>")
    $dc = @template('param_group')
    $itemUI = $dc.find('.paramItem')
    $result_container.append($dc)
    data_criteria = @builder.data_criteria[@item.id]
    if (data_criteria?)
      console.log "data_criteria=",data_criteria
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $result_container.prepend("<span class='#{subset_operator.type} subset-operator'>#{subset_operator.title()}</span>")
      
      $itemUI.append(data_criteria.asHtml("data_criteria_logic"))
      $itemUI.droppable(
        over:  @_over2
        tolerance:'pointer'
        greedy:true
        accept:'label.ui-draggable'
        out:  @_out
        drop: @_out
      )
  
      if (data_criteria.temporal_references?)
        temporal_items = data_criteria.temporalReferenceItems()
        console.log "temporal_items = ",temporal_items
        if ($.isArray(temporal_items))
          for item in temporal_items 
            $itemUI.append("<span class='#{item.conjunction} temporal-operator'>#{item.title}</span><span class='block-down-arrow'></span>")
          $div = $("<div>")  
          $div.AndContainerUI({builder:@builder,container:temporal_items[0]})
          $itemUI.append($div.children())
          
    @element.append($result_container.children())
  _over2: ->
    $(@).parents('.paramItem').removeClass('droppable2')
    $(@).addClass('droppable2')
    
  _out: ->
    $(@).removeClass('droppable').removeClass('droppable2')
  template: (id,object={}) ->
      $("#bonnie_tmpl_#{id}").tmpl(object)