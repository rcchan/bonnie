@bonnie = @bonnie || {}

class @bonnie.Builder
  constructor: (data_criteria, measure_period) ->
    @measure_period = new bonnie.MeasurePeriod(measure_period)
    @data_criteria = {}
    for key in _.keys(data_criteria)
      @data_criteria[key] = new bonnie.DataCriteria(key, data_criteria[key], @measure_period)

  dataKeys: =>
    _.keys(@data_criteria)

  dataCriteria: (key) =>
    @data_criteria[key]

  updateDisplay: () =>
    alert "updating display: " + @data_criteria

  renderMeasureJSON: (data) =>
    if (data.population)
      elemParent = bonnie.template('param_group').appendTo("#eligibilityMeasureItems").find(".paramItem:last")
      @addParamItems(data.population,elemParent,elemParent)
      elemParent.parent().addClass("population")

    if (!$.isEmptyObject(data.denominator))
      $("#eligibilityMeasureItems").append("<span class='and'>and</span>")
      @addParamItems(data.denominator,$("#eligibilityMeasureItems"))

    if (data.numerator)
      @addParamItems(data.numerator,$("#outcomeMeasureItems"))

    if ('exclusions' in data && !$.isEmptyObject(data['exclusions']))
      @addParamItems(data.exclusions,$("#exclusionMeasureItems"))
      $("#exclusionMeasureItems").hide()
      $("#exclusionPanel").show()

    $('.logicLeaf').click((element) =>
      id = $(element.currentTarget).attr('id')
      @editDataCriteria(id))

  editDataCriteria: (id) =>
    leaf = $("##{id}")
    offset = leaf.offset().top - $('#workspace').offset().top
    data_criteria = @dataCriteria(id)
    $('#workspace').empty();
    element = data_criteria.asHtml('data_criteria_edit')
    element.appendTo($('#workspace'))
    offset = offset - element.height()/2
    element.css("top",offset)

  addParamItems: (obj,elemParent,container) =>
    builder = bonnie.builder
    items = obj["items"]
    data_criteria = builder.dataCriteria(obj.id) if (obj.id)
    
    if (data_criteria?)
      if (data_criteria.subset_operators?)
        for subset_operator in data_criteria.subset_operators
          $(elemParent).append("<span class='#{subset_operator.type}'>#{subset_operator.title()}</span>")
            
      if (data_criteria.children_criteria?)
        items = data_criteria.childrenCriteriaItems()
      else
        # we dont have a nested measure clause, add the item to the bottom of the list
        # if (!elemParent.hasClass("paramItem"))
        items = data_criteria.temporalReferenceItems()
        elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last") 
        data_criteria.asHtml('data_criteria_logic').appendTo(elemParent)
    
    if ($.isArray(items))
      conjunction = obj['conjunction']
      builder.renderParamItems(conjunction, items, elemParent, container)
  
  renderParamItems: (conjunction, items, elemParent, container) =>
    builder = bonnie.builder

    elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last") if items.length > 1 and !container?

    $.each(items, (i,node) ->
      if (node.temporal)
        $(elemParent).append("<span class='#{node.conjunction}'>#{node.title}</span>")
      
      # if (!container and i == 0)
      #   if (!node.temporal && !node.items?)
      #     elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last")
      
      builder.addParamItems(node,elemParent)

      if (i < items.length-1 and !node.temporal)
        next = items[i+1]
        negation = ''
        negation = ' not' if (next['negation'])
        conjunction = node.conjunction if !conjunction
        $(elemParent).append("<span class='"+conjunction+negation+"'>"+conjunction+negation+"</span>"))
    
  
  toggleDataCriteriaTree: (element) =>
    category = $(element.currentTarget).data('category');
    children = $(".#{category}_children")
    if (children.is(':visible'))
      children.hide("blind", { direction: "vertical" }, 500)
    else
      children.show("blind", { direction: "vertical" }, 500)

  addDataCriteria: (criteria) =>
    $c = $('#dataCriteria>div.paramGroup[data-category="' + criteria.standard_category + '"]');
    if $c.length
      $e = $c.find('span')
      $e.text(parseInt($e.text()) + 1)
    else
      $c = $('
        <div class="paramGroup" data-category="' + criteria.standard_category + '">
          <div class="paramItem">
            <div class="paramText ' + criteria.standard_category + '">
              <label>' + criteria.standard_category + '<span>(1</span>)</label>
            </div>
          </div>
        </div>
      ').insertBefore('#dataCriteria .paramGroup[data-category=newDataCriteria]')
    $('
      <div class="paramChildren ' + criteria.standard_category + '_children" style="background-color: #F5F5F5;">
        <div class="paramItem">
          <div class="paramText">
            <label>' + criteria.title + (criteria.status || '') + '</label>
          </div>
        </div>
      </div>
    ').insertAfter($($c.nextUntil('#dataCriteria .paramGroup').last()[0] || $c))

class @bonnie.TemporalReference
  constructor: (temporal_reference) ->
    @offset = new bonnie.Value(temporal_reference.offset) if temporal_reference.offset
    @reference = temporal_reference.reference
    @type = temporal_reference.type
    @type_decoder = {'DURING':'During','SBS':'Starts Before Start of','SAS':'Starts After Start of','SBE':'Starts Before End of','SAE':'Starts After End of','EBS':'Ends Before Start of','EAS':'Ends After Start of'
                     ,'EBE':'Ends Before End of','EAE':'Ends After End of','SDU':'Starts During','EDU':'Ends During','ECW':'Ends Concurrent with','SCW':'Starts Concurrent with','CONCURRENT':'Concurrent with'}
  offset_text: =>
    if(@offset?)
      value = @offset.value
      unit =  @offset.unit_text()
      inclusive = @offset.inclusive_text()
      if value > 0
        ">#{inclusive} #{value} #{unit}"
      else
        "<#{inclusive} #{Math.abs(value)} #{unit}"
    else
      ''
  type_text: =>
    @type_decoder[@type]

class @bonnie.SubsetOperator
  constructor: (subset_operator) ->
    @range = new bonnie.Range(subset_operator.value) if subset_operator.value
    @type = subset_operator.type
  title: =>
    range = " #{@range.text()}" if @range
    "#{@type}#{range || ''} of"

class @bonnie.DataCriteria
  constructor: (id, criteria, measure_period) ->
    @id = id
    @oid = criteria.code_list_id
    @property = criteria.property
    @standard_category = criteria.standard_category
    @qds_data_type = criteria.qds_data_type
    @title = criteria.title
    @type = criteria.type
    @category = this.buildCategory()
    @children_criteria = criteria.children_criteria
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

  temporalReferenceItems: =>
    items = []
    if @temporal_references.length > 0
      for temporal_reference in @temporal_references
        if temporal_reference.reference != 'MeasurePeriod'
          items.push({'conjunction':temporal_reference.type, 'items': [{'id':temporal_reference.reference}], 'negation':null, 'temporal':true, 'title': "#{temporal_reference.offset_text()}#{temporal_reference.type_text()}"})
    if (items.length > 0)
      items
    else
      null

  childrenCriteriaItems: =>
    items = []
    if @children_criteria.length > 0
      for child in @children_criteria
        items.push({'conjunction':'or', 'items': [{'id':child}], 'negation':null})
    if (items.length > 0)
      items
    else
      null

  
  # get the category for the data criteria... check standard_category then qds_data_type
  # this probably needs to be done in a better way... probably direct f
  buildCategory: =>
    category = @standard_category
    # QDS data type is most specific, so use it if available. Otherwise use the standard category.
    category = @qds_data_type if @qds_data_type
    category = "patient characteristic" if category == 'individual_characteristic'
    category = category.replace('_',' ') if category
    category

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
  text: =>
    if (@high? && @low?)
      if (@high.value == @low.value and @high.inclusive and low.inclusive)
        "=#{@low.value}"
      else
        ">#{@low.inclusive_text()} #{@low.value} and <#{@high.inclusive_text()} #{@high.value}}"
    else if (@high?)
      "<#{@high.inclusive_text()} #{@high.value}"
    else if (@low?)
      ">#{@low.inclusive_text()} #{@low.value}"
    else
      ''
    
class @bonnie.Value
  constructor: (value) ->
    @type = value['type']
    @unit = value['unit']
    @value = value['value']
    @inclusive = value['inclusive?']
    @unit_decoder = {'a':'year','mo':'month','wk':'week','d':'day','h':'hour','min':'minute','s':'second'}
  unit_text: =>
    if (@unit?)
      unit = @unit_decoder[@unit]
      unit += "s " if @value != 1
    else
      ''
  inclusive_text: =>
    if (@inclusive? and @inclusive)
      '='
    else
      ''

@bonnie.template = (id, object={}) =>
  $("#bonnie_tmpl_#{id}").tmpl(object)

class Page
  constructor: (data_criteria, measure_period) ->
    bonnie.builder = new bonnie.Builder(data_criteria, measure_period)

  initialize: () =>
    $(document).on('click', '#dataCriteria .paramGroup', bonnie.builder.toggleDataCriteriaTree)
    $('.nav-tabs li').click((element) -> $('#workspace').empty() if !$(element.currentTarget).hasClass('active') )
