bonnie = @bonnie || {}

class @bonnie.Builder
  constructor: (data_criteria, measure_period, preconditions, fields, value_sets) ->
    @measure_period = new bonnie.MeasurePeriod(measure_period)
    @field_map = fields
    @data_criteria = {}
    @value_sets = {}
    @populationQuery = new queryStructure.Query()
    @denominatorQuery = new queryStructure.Query()
    @numeratorQuery = new queryStructure.Query()
    @exclusionsQuery = new queryStructure.Query()
    @exceptionsQuery = new queryStructure.Query()
    @preconditions = preconditions || {}
    @value_sets[s.oid] = s for s in value_sets
    for key in _.keys(data_criteria)
      @data_criteria[key] = new bonnie.DataCriteria(key, data_criteria[key], @measure_period)

  dataKeys: =>
    _.keys(@data_criteria)

  dataCriteria: (key) =>
    @data_criteria[key]

  updateDisplay: () =>
    alert "updating display: " + @data_criteria

  renderMeasureJSON: (data) =>
    if (!$.isEmptyObject(data.population))
      @populationQuery.rebuildFromJson(data.population)
      @addParamItems(@populationQuery.toJson(),$("#initialPopulationItems"))
      $("#initialPopulationItems .paramGroup").addClass("population")

    if (!$.isEmptyObject(data.denominator))
      @denominatorQuery.rebuildFromJson(data.denominator)
      @addParamItems(@denominatorQuery.toJson(),$("#eligibilityMeasureItems"))

    if (!$.isEmptyObject(data.numerator))
      @numeratorQuery.rebuildFromJson(data.numerator)
      @addParamItems(@numeratorQuery.toJson(),$("#outcomeMeasureItems"))

    if (!$.isEmptyObject(data.exclusions))
      @exclusionsQuery.rebuildFromJson(data.exclusions)
      @addParamItems(@exclusionsQuery.toJson(),$("#exclusionMeasureItems"))

    if (!$.isEmptyObject(data.exceptions))
      @exceptionsQuery.rebuildFromJson(data.exceptions)
      @addParamItems(@exceptionsQuery.toJson(),$("#exceptionMeasureItems"))
    @._bindClickHandler()

  _bindClickHandler: ->
    $('#initialPopulationItems, #eligibilityMeasureItems, #outcomeMeasureItems, #exclusionMeasureItems, #exceptionMeasureItems').find('.paramItem').click((event) =>
      $('.paramItem').removeClass('editing')
      $(event.currentTarget).closest('.paramItem').addClass('editing')
      @editDataCriteria(event.currentTarget)
      event.stopPropagation()
    )

  renderCriteriaJSON: (data, target) =>
    @addParamItems(data,target)

  editDataCriteria: (element) =>
    leaf = $(element)

    top = $('#workspace > div').css('top')
    $('#workspace').empty();
    element =
      if data_criteria = @dataCriteria($(element).data('criteria-id'))
        data_criteria.asHtml('data_criteria_edit').appendTo('#workspace')
      else
        bonnie.template('precondition_edit', {id: $(element).data('precondition-id')}).appendTo('#workspace')

    if data_criteria
      data_criteria.getProperty = (ns) ->
        obj = this
        y = ns.split(".")
        for i in [0..y.length-1]
          if obj[y[i]]
            obj = obj[y[i]]
          else
            return
        obj

      offset = leaf.offset().top + leaf.height()/2 - $('#workspace').offset().top - element.height()/2
      offset = 0 if offset < 0
      maxoffset = $('#measureEditContainer').height() - element.outerHeight(true) - $('#workspace').position().top - $('#workspace').outerHeight(true) + $('#workspace').height()
      offset = maxoffset if offset > maxoffset
      element.css("top", offset)
      arrowOffset = leaf.offset().top + leaf.height()/2 - element.offset().top - $('.arrow-w').outerHeight()/2
      arrowOffset = 0 if arrowOffset < 0
      $('.arrow-w').css('top', arrowOffset)
      element.css("top", top)
      element.animate({top: offset})

      element.find('select[name=status]').val(data_criteria.status)
      element.find('select[name=standard_category]').val(data_criteria.standard_category)

      temporal_element = $(element).find('.temporal_reference')
      $.each(data_criteria.temporal_references, (i, e) ->
        $(temporal_element[i]).find('.temporal_type').val(e.type)
        $(temporal_element[i]).find('.temporal_relation').val(
          (if e.offset && e.offset.value < 0 then 'lt' else 'gt') +
          if e.offset && e.offset.inclusive then 'e' else ''
        )
        $(temporal_element[i]).find('.temporal_range_high_relation').val(if e.range && e.range.high && e.range.high.inclusive then 'lte' else 'lt')
        $(temporal_element[i]).find('.temporal_range_high_unit').val(if e.range && e.range.high then e.range.high.unit)
        $(temporal_element[i]).find('.temporal_range_low_relation').val(if e.range && e.range.low && e.range.low.inclusive then 'gte' else 'gt')
        $(temporal_element[i]).find('.temporal_range_low_unit').val(if e.range && e.range.low then e.range.low.unit)
        $(temporal_element[i]).find('.temporal_drop_zone').each((i, e) ->
          fillDrop(e);
        ).droppable({ tolerance: 'pointer', greedy: true, accept: 'label.ui-draggable', drop: ((e,ui) -> fillDrop(e)) });
      );

      subset_element = $(element).find('.subset_operator')
      $.each(data_criteria.subset_operators, (i, e) ->
        $(subset_element[i]).find('.subset_type').val(e.type)
        if e.range && e.range.low && e.range.high && e.range.low.equals(e.range.high) && e.range.low.inclusive
          $(subset_element[i]).find('.subset_range_type[value=value]').attr('checked', true)
          $(subset_element[i]).find('.subset_range').hide()
        else
          $(subset_element[i]).find('.subset_range_type[value=range]').attr('checked', true)
          $(subset_element[i]).find('.subset_value').hide()
          $(subset_element[i]).find('.subset_range_high_relation').val(if e.range && e.range.high && e.range.high.inclusive then 'lte' else 'lt')
          $(subset_element[i]).find('.subset_range_low_relation').val(if e.range && e.range.low && e.range.low.inclusive then 'gte' else 'gt')
      )

      field_element = $(element).find('.field_value')
      i = 0
      $.each(data_criteria.field_values || {}, (k, e) ->
        $(f = field_element[i++]).find('.field_type').val(k)
        $(f).find('.field_oid').val(e.code_list_id)
      )

  getNextChildCriteriaId: (base, start)=>
    id = start || 1
    id++  while @data_criteria[base + id]
    base+id

  editDataCriteria_submit: (form) =>
    temporal_references = []
    subset_operators = []
    field_values = {}

    $(form).find('.temporal_reference').each((i, e) ->
      temporal_references.push({
        type: $(e).find('.temporal_type').val()
        range: {
          type: 'IVL_PQ'
          high: {
            type: 'PQ'
            value: $(e).find('.temporal_range_high_value').val()
            unit: $(e).find('.temporal_range_high_unit').val()
            'inclusive?': $(e).find('.temporal_range_high_relation').val().indexOf('e') > -1
          } if $(e).find('.temporal_range_high_value').val()
          low: {
            type: 'PQ'
            value: $(e).find('.temporal_range_low_value').val()
            unit: $(e).find('.temporal_range_low_unit').val()
            'inclusive?': $(e).find('.temporal_range_low_relation').val().indexOf('e') > -1
          } if $(e).find('.temporal_range_low_value').val()
        }
        reference: (
          if $(e).find('.temporal_reference_value').length > 1
            $.post('/measures/' + $(form).find('input[type=hidden][name=id]').val() + '/upsert_criteria', {
              criteria_id: (id = bonnie.builder.getNextChildCriteriaId($(form).find('input[type=hidden][name=criteria_id]').val() + '_CHILDREN_', id))
              children_criteria: $.map($(e).find('.temporal_reference_value'), ((e) -> $(e).val()))
              standard_category: 'temporal'
              type: 'derived'
            }) && id
          else $(e).find('.temporal_reference_value').val()
        )
      })
    )
    $(form).find('.subset_operator').each((i, e) ->
      subset_operators.push({
        type: $(e).find('.subset_type').val()
        value: {
          type: 'IVL_PQ'
          high: if $(e).find('.subset_range_type:checked').val() == 'value' then {
            type: 'PQ'
            value: $(e).find('.subset_value_value').val()
            unit: $(e).find('.subset_value_unit').val()
            'inclusive?': true
          } else {
            type: 'PQ'
            value: $(e).find('.subset_range_high_value').val()
            unit: $(e).find('.subset_range_high_unit').val()
            'inclusive?': $(e).find('.subset_range_high_relation').val().indexOf('e') > -1
          } if $(e).find('.subset_range_high_value').val()
          low: if $(e).find('.subset_range_type:checked').val() == 'value' then {
            type: 'PQ'
            value: $(e).find('.subset_value_value').val()
            unit: $(e).find('.subset_value_unit').val()
            'inclusive?': true
          } else {
            type: 'PQ'
            value: $(e).find('.subset_range_low_value').val()
            unit: $(e).find('.subset_range_low_unit').val()
            'inclusive?': $(e).find('.subset_range_low_relation').val().indexOf('e') > -1
          } if $(e).find('.subset_range_low_value').val()
        }
      })
    )
    $(form).find('.field_value').each((i, e) =>
      field_values[$(e).find('.field_type').val()] = {
        code_list_id: oid = $(e).find('.field_oid').val()
        title: @value_sets[oid].concept
        type: 'CD'
      }
    )
    !$(form).ajaxSubmit({
      data: {
        temporal_references: JSON.stringify(temporal_references)
        subset_operators: JSON.stringify(subset_operators)
        field_values: JSON.stringify(field_values)
      }
      success: (changes) =>
        criteria = @data_criteria[changes.id] = $.extend(@data_criteria[changes.id], changes)
        $element = $('#' + changes.id)
        $element.find('label').text(criteria.buildCategory())
        @showSaved(@)
    });

  showSaved: (e) =>
    $(e).find('.edit_save_message').empty().append('<span style="color: green">Saved!</span>')
    setTimeout (->
      $(e).find(".edit_save_message > span").fadeOut ->
        $(this).remove()
    ), 3000

  addParamItems: (obj,elemParent,container) =>
    builder = bonnie.builder
    items = obj["items"]
    data_criteria = builder.dataCriteria(obj.id) if (obj.id)
    parent = obj.parent

    push = (query, key, title) ->
      ((o) ->
        delete o.parent
        for k of o
          arguments.callee o[k]  if typeof o[k] is "object"
      ) query = query
      $.post(bonnie.builder.update_url, {'csrf-token': $('meta[name="csrf-token"]').attr('content'), data: {'conjunction?': true, type: key, title: title, preconditions: query}})

    makeDropFn = (self) ->
      queryObj = parent ? obj
      dropFunction = (event,ui) ->
        target = event.currentTarget
        drop_Y = event.pageY
        child_items = $(@).children(".paramGroup")
        for item in child_items
          item_top = $(item).offset().top;
          item_height = $(item).height();
          item_mid = item_top + Math.round(item_height/2)
        # tgt = queryObj.parent ? queryObj
        if queryObj instanceof queryStructure.Container
          tgt = queryObj
        else
          tgt = queryObj.parent
        tgt?.add(
          id: $(ui.draggable).data('criteria-id')
        )
        $(@).removeClass('droppable')
        $('#workspace').empty()

        finder = queryObj
        switch (
          (while finder.parent
            finder = finder.parent
          ).pop()
        )
          when bonnie.builder.populationQuery.structure
            bonnie.builder.addParamItems((query = bonnie.builder.populationQuery.toJson()),$("#initialPopulationItems").empty())
            push(query, 'IPP', 'Initial Patient Population')
          when bonnie.builder.denominatorQuery.structure
            bonnie.builder.addParamItems((query = bonnie.builder.denominatorQuery.toJson()),$("#eligibilityMeasureItems").empty())
            push(query, 'DENOM', 'Denominator')
          when bonnie.builder.numeratorQuery.structure
            bonnie.builder.addParamItems((query = bonnie.builder.numeratorQuery.toJson()),$("#outcomeMeasureItems").empty())
            push(query, 'NUMER', 'Numerator')
          when bonnie.builder.exclusionsQuery.structure
            bonnie.builder.addParamItems((query = bonnie.builder.exclusionsQuery.toJson()),$("#exclusionMeasureItems").empty())
            push(query, 'EXCL', 'Exclusions')
          when bonnie.builder.exceptionsQuery.structure
            bonnie.builder.addParamItems((query = bonnie.builder.exceptionsQuery.toJson()),$("#exceptionMeasureItems").empty())
            push(query, 'DENEXCEP', 'Denominator Exceptions')

        self._bindClickHandler()
      return dropFunction


    if $(elemParent).not(".droppable").hasClass('paramItem')
      $(elemParent).data("query-struct",parent)
      elemParent.droppable(
          over:  @._over
          tolerance:'pointer'
          greedy: true
          accept:'label.ui-draggable'
          out:  @._out
          drop: makeDropFn(@)

      )
    if (data_criteria?)
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $(elemParent).append("<span class='#{subset_operator.type} subset-operator'>#{subset_operator.title()}</span>")

      if (data_criteria.children_criteria?)
        items = data_criteria.childrenCriteriaItems()
      else
        # we dont have a nested measure clause, add the item to the bottom of the list
        # if (!elemParent.hasClass("paramItem"))
        items = data_criteria.temporalReferenceItems()
        elemParent = bonnie.template('param_group', obj).appendTo(elemParent).find(".paramItem:last")
        $(elemParent).parent().find('.display_name').click((e)->
          $(this).siblings().slideToggle();
          e.stopPropagation()
        );
        data_criteria.asHtml('data_criteria_logic').appendTo(elemParent)

    if ($.isArray(items))
      conjunction = obj['conjunction']
      builder.renderParamItems(conjunction, items, elemParent, container, obj)

  _over: ->
    $(@).parents('.paramItem').removeClass('droppable')
    $(@).addClass('droppable')

  _out: ->
    $(@).removeClass('droppable')

  renderParamItems: (conjunction, items, elemParent, container, obj) =>
    neg = (obj.negation || false) && obj.negation != 'false'
    builder = bonnie.builder

    if items.length > 1 and !container?
      elemParent = bonnie.template('param_group', obj).appendTo(elemParent).find(".paramItem:last")
      $(elemParent).parent().find('.display_name').click((e)->
        $(this).siblings().slideToggle();
        e.stopPropagation()
      );

    $.each(items, (i,node) ->
      $(elemParent).append("<span class='not'>not</span>") if neg

      if (node.temporal)
        $(elemParent).append("<span class='#{node.conjunction} temporal-operator'>#{node.title}</span><span class='block-down-arrow'></span>")

      # if (!container and i == 0)
      #   if (!node.temporal && !node.items?)
      #     elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last")
      builder.addParamItems(node,elemParent)
      if (i < items.length-1 and !node.temporal)
        next = items[i+1]
        conjunction = node.conjunction if !conjunction
        $(elemParent).append("<span class='"+conjunction+"'>"+conjunction+"</span>")
    )


  toggleDataCriteriaTree: (element) =>
    $(element.currentTarget).closest(".paramGroup").find("i").toggleClass("icon-chevron-right").toggleClass("icon-chevron-down")
    category = $(element.currentTarget).data('category');
    children = $(".#{category}_children")
    if (children.is(':visible'))
      children.hide("blind", { direction: "vertical" }, 500)
    else
      children.show("blind", { direction: "vertical" }, 500)

  addDataCriteria: (criteria) =>
    @data_criteria[criteria.id] = criteria = new bonnie.DataCriteria(criteria.id, criteria)
    $c = $('#dataCriteria>div.paramGroup[data-category="' + criteria.buildCategory() + '"]');
    if $c.length
      $e = $c.find('span')
      $e.text(parseInt($e.text()) + 1)
    else
      $c = $('
        <div class="paramGroup" data-category="' + criteria.buildCategory() + '">
          <div class="paramItem">
            <div class="paramText ' + criteria.buildCategory() + '">
              <label>' + criteria.standard_category + '(<span>1</span>)</label>
            </div>
          </div>
        </div>
      ').insertBefore('#dataCriteria .paramGroup[data-category=newDataCriteria]')
    $('
      <div class="paramItem">
        <div class="paramText">
          <label>' + criteria.title + (if criteria.status then ': '+ criteria.status else '') + '</label>
        </div>
      </div>
    ').appendTo(
      $(
        $c.nextUntil('#dataCriteria .paramGroup', '#dataCriteria .paramChildren')[0] ||
        $('<div class="paramChildren ' + criteria.buildCategory() + '_children" style="background-color: #F5F5F5;"></div>').insertAfter($c)
      )
    )

class @bonnie.TemporalReference
  constructor: (temporal_reference) ->
    @range = new bonnie.Range(temporal_reference.range) if temporal_reference.range
    @reference = temporal_reference.reference
    @type = temporal_reference.type
    @type_decoder = {'DURING':'During','SBS':'Starts Before Start of','SAS':'Starts After Start of','SBE':'Starts Before End of','SAE':'Starts After End of','EBS':'Ends Before Start of','EAS':'Ends After Start of'
                     ,'EBE':'Ends Before End of','EAE':'Ends After End of','SDU':'Starts During','EDU':'Ends During','ECW':'Ends Concurrent with','SCW':'Starts Concurrent with','CONCURRENT':'Concurrent with'}
  offset_text: =>
    if(@range)
      @range.text(true)
    else
      ''
  type_text: =>
    @type_decoder[@type]

class @bonnie.SubsetOperator
  constructor: (subset_operator) ->
    @range = new bonnie.Range(subset_operator.value) if subset_operator.value
    @type = subset_operator.type
    @type_decoder = {'COUNT':'count', 'FIRST':'first', 'SECOND':'second', 'THIRD':'third', 'FOURTH':'fourth', 'FIFTH':'fifth', 'RECENT':'most recent', 'LAST':'last', 'MIN':'min', 'MAX':'max'}

  title: =>
    range = " #{@range.text()}" if @range
    "#{@type_decoder[@type]}#{range || ''} of"

class @bonnie.DataCriteria
  constructor: (id, criteria, measure_period) ->
    @id = id
    @oid = criteria.code_list_id
    @property = criteria.property
    @title = criteria.title
    @type = criteria.type
    @definition = criteria.definition
    @display_name = criteria.display_name
    @field_values = criteria.field_values
    @specific_occurrence = criteria.specific_occurrence
    if @field_values?
      for key in _.keys(@field_values)
        value = @field_values[key]
        if value?
          value = new bonnie.Range(value) if value.type == 'IVL_PQ'
          value = new bonnie.Value(value) if value.type == 'PQ'
          value = new bonnie.Coded(value) if value.type == 'CD'
        @field_values[key] = value
    
    if criteria.value
      @value = new bonnie.Range(criteria.value) if criteria.value.type == 'IVL_PQ'
      @value = new bonnie.Value(criteria.value) if criteria.value.type == 'PQ'
      @value = new bonnie.Coded(criteria.value) if criteria.value.type == 'CD'
    @category = this.buildCategory()
    @status = criteria.status
    @children_criteria = criteria.children_criteria
    @derivation_operator = criteria.derivation_operator
    @temporal_references = []
    if criteria.temporal_references
      for temporal in criteria.temporal_references
        @temporal_references.push(new bonnie.TemporalReference(temporal))
    @subset_operators = []
    if criteria.subset_operators
      for subset in criteria.subset_operators
        @subset_operators.push(new bonnie.SubsetOperator(subset))

    @temporalText = this.temporalText(measure_period)

  asHtml: (template) =>
    bonnie.template(template,this)

  temporalText: (measure_period) =>
    text = ''
    for temporal_reference in @temporal_references
      if temporal_reference.reference == 'MeasurePeriod'
        text += ' and ' if text.length > 0
        text += "#{temporal_reference.offset_text()}#{temporal_reference.type_text()} #{measure_period.name}"
    text
  valueText: =>
    text = ''
    text += "(result #{@value.text()})" if @value?

  fieldsText: =>
    text = ''
    if @field_values?
      text += '('
      i=0
      for key in _.keys(this.field_values)
        text+=', ' if i > 0
        i+=1
        field_value = ''
        field_value = @field_values[key].text() if @field_values[key]?
        text+="#{bonnie.builder.field_map[key].title}:#{field_value}"
      text += ')'
    text

  temporalReferenceItems: =>
    items = []
    if @temporal_references.length > 0
      for temporal_reference in @temporal_references
        if temporal_reference.reference && temporal_reference.reference != 'MeasurePeriod'
          items.push({'conjunction':temporal_reference.type, 'items': [{'id':temporal_reference.reference}], 'negation':null, 'temporal':true, 'title': "#{temporal_reference.offset_text()}#{temporal_reference.type_text()}"})
    if (items.length > 0)
      items
    else
      null

  childrenCriteriaItems: =>
    items = []
    if @children_criteria.length > 0
      conjunction = 'or'
      conjunction = 'and' if @derivation_operator == 'XPRODUCT'
      for child in @children_criteria
        items.push({'conjunction':conjunction, 'items': [{'id':child}], 'negation':null})
    if (items.length > 0)
      items
    else
      null

  # get the category for the data criteria
  buildCategory: =>
    return 'patient characteristic' if (@type == 'characteristic')
    @definition.replace(/_/g,' ')

class @bonnie.MeasurePeriod
  constructor: (measure_period) ->
    @name = "the measurement period"
    @type = measure_period['type']
    @high = new bonnie.Value(measure_period['high'])
    @low = new bonnie.Value(measure_period['low'])
    @width = new bonnie.Value(measure_period['width'])

class @bonnie.Range
  constructor: (range) ->
    @type = range['type']
    @high = new bonnie.Value(range['high']) if range['high']
    @low = new bonnie.Value(range['low']) if range['low']
    @width = new bonnie.Value(range['width']) if range['width']
  text: (temporal=false)=>
    if (@high? && @low?)
      if (@high.value == @low.value and @high.inclusive and @low.inclusive)
        "#{@low.text(temporal)}"
      else
        ">#{@low.text(temporal)} and <#{@high.text(temporal)}"
    else if (@high?)
      "<#{@high.text(temporal)}"
    else if (@low?)
      ">#{@low.text(temporal)}"
    else
      ''

class @bonnie.Value
  constructor: (value) ->
    @type = value['type']
    @unit = value['unit']
    @value = value['value']
    @inclusive = value['inclusive?']
    @temporal_unit_decoder = {'a':'year','mo':'month','wk':'week','d':'day','h':'hour','min':'minute','s':'second'}
  temporal_unit_text: =>
    if (@unit?)
      unit = @temporal_unit_decoder[@unit]
      unit += "s " if @value != 1
    else
      ''
  text: (temporal=false) =>
    text = "#{@inclusive_text()} #{@value}"
    if (temporal)
      text += " #{@temporal_unit_text()}"
    else
      text += @unit if @unit?
    text
  inclusive_text: =>
    if (@inclusive? and @inclusive)
      '='
    else
      ''
  equals: (other) ->
    return @type == other.type && @value == other.value && @unit == other.unit && @inclusive == other.inclusive

class @bonnie.Coded
  constructor: (value) ->
    @type = value['type']
    @title = value['title'] || ''
    @system = value['system']
    @code = value['code']
    @code_list_id = value['code_list_id']
  text: =>
    if (@title? and @title.length > 0)
      ": #{@title}"
    else
      ": #{@code}"
    
@bonnie.template = (id, object={}) =>
  $("#bonnie_tmpl_#{id}").tmpl(object)

class Page
  constructor: (data_criteria, measure_period, update_url, preconditions, fields, value_sets) ->
    bonnie.builder = new bonnie.Builder(data_criteria, measure_period, preconditions, fields, value_sets)
    bonnie.builder['update_url'] = update_url

  initialize: () =>
    $(document).on('click', '#dataCriteria .paramGroup', bonnie.builder.toggleDataCriteriaTree)
    $('.nav-tabs li').click((element) -> $('#workspace').empty() if !$(element.currentTarget).hasClass('active') )
