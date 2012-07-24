
    
$.widget 'ui.ContainerUI',
  options: {}
  _create: ->
  _init: ->
    #@element.addClass('widget')
    @container = @options.container
    @parent = @options.parent
    @builder = @options.builder
    @_createContainer()

  _createContainer: ->
    $inner = $("<div>")
    if @container.children?
      for child,i in @container.children
        #console.log("child = ",child)
        childItem = @_createItemUI(child)
        @element.append childItem
        if (i < @container.children.length-1)
          if @container instanceof queryStructure.AND then conjunction="and" else conjunction="or"
          @element.append("<span class='"+conjunction+"'>"+conjunction+"</span>")
    return $inner.children()
      
  _createItemUI: (item) ->
    # we need a temporary container outside of the param_group
    $result_container = $("<div>")
    if item.children
      if (!(item instanceof queryStructure.AND) && !(item instanceof queryStructure.OR))
        @element.ItemUI(
          parent:@
          item:item.children[0]
        )
      else
        makeDropFn = (self) ->
          currentItem = item
          #console.log "make Container Drop item = " ,self.container
          dropFn = (event,ui) ->
            ###
            console.log("Dropped on a container",self.container)
            console.log("Dropped on me", currentItem)
            console.log "event = ",event
            console.log "ui = ",ui
            console.log "ui.draggable = ",ui.draggable
            console.log "ui.draggable.data = ",ui.draggable.data()
            console.log "ui.draggable.paramText.data = ",ui.draggable.find(".paramText").data()
            ###
            orig = ui.draggable.data('item-ui') ? {} 
            console.log("orig=",orig)
            target = event.currentTarget
            dropY = event.pageY
            child_items = $(@).children(".paramGroup")
            after = null
            before = child_items[0] if child_items.length
            pos = 0
            for item,i in child_items
              item_top = $(item).offset().top;
              item_height = $(item).height();
              item_mid = item_top + Math.round(item_height/2)
              before = currentItem.children[i] if dropY < item_mid
              after = currentItem.children[i] if dropY > item_mid
              pos = i+1 if dropY > item_mid
            #console.log("after=",after)
            id = $(ui.draggable).data('criteria-id')
            if (orig.parent? && orig.parent is currentItem)
              console.log("Dropped on my own box")
              console.log("orig = ",orig)
              console.log("after= ",after)
              c1 = currentItem.removeChild(orig)
              currentItem.add(c1,after)
            else
              currentItem.add(
                id: id
                data_criteria:self.builder.data_criteria[id]
              after
              )
            $(ui.helper).remove()
            scrollTop = Math.max($("html").scrollTop(),$("body").scrollTop())
            #console.log("scrollTop was",scrollTop)

            self.element.empty().AndContainerUI({builder:self.builder,container:self.container})
            $("body,html").scrollTop(scrollTop)
            droppedElem = self.element.find(".paramItem[data-myid=#{currentItem.myid}]>.paramGroup").eq(pos)
            #console.log droppedElem
            innerHeight = window.innerHeight
            scrollTop = Math.max($("html").scrollTop(),$("body").scrollTop())
            #console.log("scrollTop is", scrollTop)
            if droppedElem.offset().top > innerHeight*.75 or droppedElem.offset().top - scrollTop < 0
              $.scrollTo(droppedElem,
                duration:800
                easing:'easeInOutQuad'
                offset:
                  top:Math.floor(innerHeight/2) * -1
                onAfter: =>
                  droppedElem.addClass('dropped')
              )
            else
              droppedElem.addClass('dropped')

            _.bind(self._drop,@)()
            
          return dropFn
        neg = (item.negation || false) && item.negation != 'false'
        if neg is true
          $itemUI = $result_container
          $result_container.append("<span class='not'>not</span>")
        else
          $dc = @template('param_group',item)
          $result_container.append($dc)
          $itemUI = $dc.find('.paramItem')
          $dc.addClass(if @container instanceof queryStructure.AND then "and" else "or")
          $dc.find(".paramItem").droppable(
            over: @_over
            tolerance:'pointer'
            out: @_out
            drop: makeDropFn(@)
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
      console.log("setting ItemUI = ", item)
      $dc = @template('param_group',item)
      $result_container.append($dc)
      $itemUI = $dc.find('.paramItem')
      $itemUI.ItemUI(
        parent:@
        item:item
      )
      $itemUI.data("item-ui",item)
      console.log "@element is ", @element
    return $result_container.children()
  template: (id,object={}) =>
      $("#bonnie_tmpl_#{id}").tmpl(object)
  _over: ->
    $(@).toggleClass('droppable',true)
  _out: ->
    $(@).toggleClass('droppable',false)
  _drop: ->
    window.setTimeout( -> $(".dropped").removeClass('xdropped'),
    4500
    )
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
    @item = @options['item']
    @_createItem()
    
  _createItem: ->
    $result_container = $("<div>")
    $dc = @template('param_group',@item)
    $itemUI = $dc.find('.paramItem')
    $itemUI = @element
    @item.rnd = Math.floor(Math.random()*100)
    console.log('rnd=',@item.rnd)
    $itemUI.click((event) =>
      $('.paramItem').removeClass('editing')
      $(event.currentTarget).closest('.paramItem').addClass('editing')
      @builder.editDataCriteria(event.currentTarget.firstElementChild)
      event.stopPropagation()
    )
    makeDropFn = (self) ->
      #console.log "make Drop item = " ,self.item
      dropFn = (event,ui) ->
        target = event.currentTarget
        dropY = event.pageY
        childItems = $(@).children(".paramGroup")
        _.bind(self._drop,@)()
        
      return dropFn

    makeGroupDropFn = (self,container) ->
      currentItem = self.builder.data_criteria[self.item.id].children_criteria
      console.log("makeGroupDrop currentItem = ",currentItem)
      console.log("makeGroupDrop self=",self)
      #console.log "make Container Drop item = " ,self.container
      container = container
      parent = self.item.parent
      dropFn = (event,ui) ->
        console.log("---------starting dropFn--------------")
        console.log("self = ",self)
        console.log("container = ",container)
        console.log("self.element=",self.element)
        console.log("currentItem=",currentItem)
        console.log("@=",@)
        console.log("parent=",parent)
        origId = ui.draggable.data('criteria-id') ? null
        console.log("origId=",origId)
        target = event.currentTarget
        dropY = event.pageY
        child_items = $(@).children(".paramGroup")
        after = null
        before = child_items[0] if child_items.length
        pos = 0
        for item,i in child_items
          item_top = $(item).offset().top;
          item_height = $(item).height();
          item_mid = item_top + Math.round(item_height/2)
          pos = i+1 if dropY > item_mid
        #console.log("after=",after)
        currentItem.splice(pos,0,origId) if origId?
        $(ui.helper).remove()
        scrollTop = Math.max($("html").scrollTop(),$("body").scrollTop())
        #console.log("scrollTop was",scrollTop)

        $(@).empty().closest(".paramGroup>.paramItem").OrContainerUI({builder:self.builder,container:parent})
        $("body,html").scrollTop(scrollTop)
        droppedElem = self.element #.find(".paramItem[data-myid=#{currentItem.myid}]>.paramGroup").eq(pos)
        #console.log droppedElem
        innerHeight = window.innerHeight
        scrollTop = Math.max($("html").scrollTop(),$("body").scrollTop())
        #console.log("scrollTop is", scrollTop)
        if droppedElem.offset().top > innerHeight*.75 or droppedElem.offset().top - scrollTop < 0
          $.scrollTo(droppedElem,
            duration:800
            easing:'easeInOutQuad'
            offset:
              top:Math.floor(innerHeight/2) * -1
            onAfter: =>
              droppedElem.addClass('dropped')
          )
        else
          droppedElem.addClass('dropped')

        _.bind(self._drop,@)()
        
      return dropFn

      
    #$result_container.append($dc)
    data_criteria = @builder.data_criteria[@item.id]
    if (data_criteria?)
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $result_container.prepend("<span class='#{subset_operator.type} subset-operator'>#{subset_operator.title()}</span>")
      
      if (data_criteria.children_criteria?)
        items = data_criteria.childrenCriteriaItems()
        if $.isArray(items)
          $div = $("<div>")
          conjunction = items[0].conjunction
          # What is the correct queryStructure here?
          if conjunction == 'or'
            child_criteria = new queryStructure.OR(@parent,items)
          else
            child_criteria = new queryStructure.AND(@parent,items)
          $div.AndContainerUI({builder:@builder,container:child_criteria})
          ### 
          This is where we have drawn the child group of items, but need to add the drop handler to the exterior container
          ###
          console.log("group item = ",@item)
          $itemUI.droppable(
            over: @_overGroup
            tolerance:'pointer'
            greedy:true
            accept:'label.ui-draggable'
            out:  @_outGroup
            drop: makeGroupDropFn(@,child_criteria.children)
          )
          $itemUI.append($div.children())
      else
        $itemUI.append(data_criteria.asHtml("data_criteria_logic"))
        #$itemUI.find(".paramText").data('item-ui', @item)
        #console.log("item-ui data=",$itemUI.find(".paramText").data('item-ui'))
        $itemUI.droppable(
          over:  @_over
          tolerance:'pointer'
          greedy:true
          accept:'label.ui-draggable'
          out:  @_out 
          drop: makeDropFn(@)
        )
        $itemUI.draggable(
          helper: "clone"
          revert:true
          distance:3
          handle: '.paramText'
          opacity:1
          zIndex:10000
          start: (event,ui) ->
            #$(".paramGroup:has(.paramItem.dragged)").addClass("dragged")
            #console.log("item-ui data=",$itemUI.find('.paramText').data("item-ui"))
            $(event.target).closest(".paramGroup").addClass("dragged")
            $(ui.helper).find('.paramText').siblings().hide()
            $(ui.helper).width($(@).closest('.paramItem').width()+12)
          stop: (event,ui) ->
            $(event.target).closest(".paramGroup").removeClass("dragged")
        )
        
        if (data_criteria.temporal_references?)
          temporal_items = data_criteria.temporalReferenceItems()
          if ($.isArray(temporal_items))
            for item,i in temporal_items 
              $itemUI.append("<span class='#{item.conjunction} temporal-operator'>#{item.title}</span><span class='block-down-arrow'></span>")
              $div = $("<div>")  
              $div.AndContainerUI({builder:@builder,container:temporal_items[i]})
              $itemUI.append($div.children())
    @element.parent().parent().prepend($result_container.children())
  # Using different colors in the drop highlighting to aid in debugging  
  _over: ->
    $(@).toggleClass('droppable2',true)
  _overGroup: ->
    $(@).toggleClass('droppable3',true)
  _outGroup: ->
    $(@).toggleClass('droppable3',false)
  _out: ->
    $(@).toggleClass('droppable2',false)
  _drop: ->
    console.log("in drop")
    console.log(@)
    $(@).removeClass('droppable2').removeClass('droppable3')

  template: (id,object={}) ->
      $("#bonnie_tmpl_#{id}").tmpl(object)