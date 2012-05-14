@bonnie = @bonnie || {}

class @bonnie.Builder
  constructor: (data_criteria) ->
    @data_criteria = {}
    for key in _.keys(data_criteria)
      @data_criteria[key] = new bonnie.DataCriteria(data_criteria[key])
      
  dataKeys: ->
    _.keys(@data_criteria)
    
  dataCriteria: (key) ->
    @data_criteria[key]
  
  updateDisplay: () ->
    alert "updating display: " + @data_criteria
    
  getTemplate: (group, id, obj={}) ->
    $.tmpl(bonnie.Templates[group][id](),obj)
    
  renderMeasureJSON: (data) ->
    builder = bonnie.builder
    if (data.population)
      elemParent = builder.getTemplate('logic','paramGroup').appendTo("#eligibilityMeasureItems").find(".paramItem:last")
      builder.addParamItems(data.population,elemParent,elemParent)
      elemParent.parent().addClass("population")

    if (!$.isEmptyObject(data.denominator)) 
      $("#eligibilityMeasureItems").append("<span class='and'>and</span>")
      builder.addParamItems(data.denominator,$("#eligibilityMeasureItems"))

    if (data.numerator) 
      builder.addParamItems(data.numerator,$("#outcomeMeasureItems"))

    if ('exclusions' in data && !$.isEmptyObject(data['exclusions']))
      builder.addParamItems(data.exclusions,$("#exclusionMeasureItems"))
      $("#exclusionMeasureItems").hide()
      $("#exclusionPanel").show()

    $('.logicLeaf').click((element) -> 
      leaf = $(element.currentTarget)
      offset = leaf.offset().top - $('#workspace').offset().top
      bonnie.showDataCriteria(leaf.data('id'), offset))

  addParamItems: (obj,elemParent,container) ->
    builder = bonnie.builder
    items = obj["items"]

    if $.isArray(items)
      conjunction = obj['conjunction']
      # add the grouping container
      elemParent = bonnie.builder.getTemplate('logic','paramGroup').appendTo(elemParent).find(".paramItem:last") if (!container)

      $.each(items, (i,node) ->
        builder.addParamItems(node,elemParent)
        if (i < items.length-1)
          next = items[i+1]
          negation = ''
          negation = ' not' if (next['negation'])
          $(elemParent).append("<span class='"+conjunction+negation+"'>"+conjunction+negation+"</span>"))
    else
      # we dont have a nested measure clause, add the item to the bottom of the list
      if (!elemParent.hasClass("paramItem"))
        elemParent = bonnie.builder.getTemplate('logic','paramGroup').appendTo(elemParent).find(".paramItem:last")
      bonnie.builder.dataCriteria(obj.id).asHtml('logic').appendTo(elemParent)
  

class @bonnie.DataCriteria
  constructor: (criteria) ->
    @oid = criteria.code_list_id
    @property = criteria.property
    @standard_category = criteria.standard_category
    @qds_data_type = criteria.qds_data_type
    @title = criteria.title
    @type = criteria.type
    @category = this.buildCategory()
    @temporalText = this.temporalText(criteria)
  
  asHtml: (template) ->
    bonnie.builder.getTemplate('logic','dataCriteria',this)
    
  temporalText: (criteria) ->
    # Some exceptions have the value key. Bump it forward so criteria is idenical to the format of usual coded entries
    if criteria["value"] 
      value = criteria["value"]
    else # Find the display name as per usual for the coded entry
      effective_time = criteria["effective_time"] if criteria["effective_time"]
    
    measure_period["name"] = "the measure period"
    temporal_text = parse_hqmf_time(effective_time || value || criteria, measure_period)
    title = "#{name} #{temporal_text}"
    
  
  buildCategory: ->
    category = @standard_category
    # QDS data type is most specific, so use it if available. Otherwise use the standard category.
    category = @qds_data_type if @qds_data_type
    category = "patient characteristic" if category == 'individual_characteristic'
    category = category.replace('_',' ') if category
    category

@bonnie.Templates = {
  logic: {
    dataCriteria: ->
      "
      <div class='paramText {{if category}}${category}{{/if}} logicLeaf' {{if id}}data-id='${id}'{{/if}}>
        {{if category}}<label>${category}</label>{{/if}}
        ${title}
      </div>
      "
    paramGroup: ->
      "
      <div class='paramGroup'>
        <div class='paramItem'></div>
      </div>
      "
  }
}

class Page
  constructor: (data_criteria) ->
    bonnie.builder = new bonnie.Builder(data_criteria)
