
    
$.widget 'ui.ContainerUI',
  options: {}
  _create: ->
  _init: ->
    @container = @options.container
    @parent = @options.parent
    @builder = @options.builder
    cc= @_createContainer()
    #@builder._bindClickHandler()

  _createContainer: ->
    $inner = $("<div>")
    if @container.children?
      for child,i in @container.children
        childItem = @_createItemUI(child)
        @element.append childItem
        if (i < @container.children.length-1)
          if @container instanceof queryStructure.AND then conjunction="and" else conjunction="or"
          @element.append("<span class='"+conjunction+"'>"+conjunction+"</span>")
    return $inner.children()
      
  _createItemUI: (item) ->
    # we need a container outside of the param_group
    $result_container = $("<div>")
    if item.children
      if (!(item instanceof queryStructure.AND) && !(item instanceof queryStructure.OR))
        @element.ItemUI(
          parent:@
          item:item.children[0]
        )
      else
        if item.negation is true
          $itemUI = $result_container
          $result_container.append("<span class='not'>not</span>")
        else
          $dc = @template('param_group')
          $result_container.append($dc)
          $itemUI = $dc.find('.paramItem')
          $dc.addClass(if @container instanceof queryStructure.AND then "and" else "or")
          $dc.find(".paramItem").droppable(
            over: @_over
            out: @_out
            drop: @_drop
            greedy:true
          )
        if item instanceof queryStructure.AND
          $itemUI.AndContainerUI(
            parent: @
            container: item
            builder: @builder
          )
        if item instanceof queryStructure.OR
          $itemUI.OrContainerUI(
            parent: @
            container: item
            builder: @builder
          )

    else 
      @element.ItemUI(
        parent:@
        item:item
      )
    return $result_container.children()
  template: (id,object={}) ->
      $("#bonnie_tmpl_#{id}").tmpl(object)
  _over: ->
    $(@).toggleClass('droppable',true)
  _out: ->
    $(@).toggleClass('droppable',false)
  _drop: ->
    $(@).toggleClass('droppable',false)

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
    @parent = @options.parent
    @builder = @options.builder ? @parent.builder
    @item = @options.item
    @_createItem()
    
  _createItem: ->
    $result_container = $("<div>")
    $dc = @template('param_group')
    $itemUI = $dc.find('.paramItem')
    
    $itemUI.click((event) =>
      event.stopPropagation()
      $('.paramItem').removeClass('editing')
      $(event.currentTarget).closest('.paramItem').addClass('editing')
      @builder.editDataCriteria(event.currentTarget.firstElementChild)
    )  
    $result_container.append($dc)
    data_criteria = @builder.data_criteria[@item.id]
    if (data_criteria?)
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $result_container.prepend("<span class='#{subset_operator.type} subset-operator'>#{subset_operator.title()}</span>")
      
      if (data_criteria.children_criteria?)
        items = data_criteria.childrenCriteriaItems()
        if $.isArray(items)
          $div = $("<div>")
          # What is the correct queryStructure here?
          foo = new queryStructure.OR(@parent,items)
          $div.AndContainerUI({builder:@builder,container:foo})
          $itemUI.append($div.children())
      else
        $itemUI.append(data_criteria.asHtml("data_criteria_logic"))
        $itemUI.droppable(
          over:  @_over
          tolerance:'pointer'
          greedy:true
          accept:'label.ui-draggable'
          out:  @_out 
          drop: @_drop
        )
        $itemUI.draggable(
          helper:"clone"
          containment:'document'
          revert:true
          distance:3
          opacity:1
        )
        
        if (data_criteria.temporal_references?)
          temporal_items = data_criteria.temporalReferenceItems()
          if ($.isArray(temporal_items))
            for item,i in temporal_items 
              $itemUI.append("<span class='#{item.conjunction} temporal-operator'>#{item.title}</span><span class='block-down-arrow'></span>")
              $div = $("<div>")  
              $div.AndContainerUI({builder:@builder,container:temporal_items[i]})
              $itemUI.append($div.children())
    @element.append($result_container.children())
  _over: ->
    $(@).toggleClass('droppable2',true)
  _out: ->
    $(@).toggleClass('droppable2',false)
  _drop: ->
    $(@).toggleClass('droppable2',false)

  template: (id,object={}) ->
      $("#bonnie_tmpl_#{id}").tmpl(object)