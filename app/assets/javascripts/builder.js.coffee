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

    if $.isArray(items)
      conjunction = obj['conjunction']
      # add the grouping container
      elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last") if (!container)

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
        elemParent = bonnie.template('param_group').appendTo(elemParent).find(".paramItem:last")
      bonnie.builder.dataCriteria(obj.id).asHtml('data_criteria_logic').appendTo(elemParent)

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
    @temporalText = this.temporalText(criteria, measure_period)

  asHtml: (template) =>
    bonnie.template(template,this)

  temporalText: (criteria, measure_period) =>
    # Some exceptions have the value key. Bump it forward so criteria is identical to the format of usual coded entries
    if criteria["value"]
      value = criteria["value"]
    else # Find the display name as per usual for the coded entry
      effective_time = criteria["effective_time"] if criteria["effective_time"]

    temporal_text = @parse_hqmf_time(effective_time || value || criteria, measure_period)
    title = "#{name} #{temporal_text}"

  # This is a helper for parse_hqmf_data_criteria.
  # Return recursively generated human readable text about time ranges and periods
  parse_hqmf_time: (criteria, relative_time) =>
    temporal_text = ""
    type = criteria["type"]
    switch type
      when "IVL_TS"
        temporal_text = "#{@parse_hqmf_time(criteria["width"], relative_time)} " if criteria["width"]
        temporal_text += ">#{@parse_hqmf_time_stamp("low", criteria, relative_time)} start" if criteria["low"]
        temporal_text += " and " if criteria["low"] && criteria["high"]
        temporal_text += "<#{@parse_hqmf_time_stamp("high", criteria, relative_time)} end" if criteria["high"]
      when "IVL_PQ"
        temporal_text = @parse_hqmf_time_vector(criteria["low"], ">") if criteria["low"]
        temporal_text += " and " if criteria["low"] && criteria["high"]
        temporal_text += @parse_hqmf_time_vector(criteria["high"], "<") if criteria["high"]
    temporal_text

  parse_hqmf_time_stamp: (point, timestamp, relative_timestamp) =>
    if timestamp[point]["value"] == relative_timestamp[point]["value"]
      "= #{relative_timestamp["name"]}"
    else
      year = timestamp[point]["value"][0..3]
      month = timestamp[point]["value"][4..5]
      day = timestamp[point]["value"][6..7]
      " #{Time.new(year, month, day).strftime("%m/%d/%Y")}"

  parse_hqmf_time_vector: (vector, symbol) =>
    decoder = {'a':'year','mo':'month','d':'day','h':'hour','min':'minute'}
    inclusive = if vector["inclusive?"] then '=' else ''
    unit = decoder[vector["unit"]]
    unit += "s" if vector["value"] != 1
    temporal_text = "#{symbol}#{inclusive} #{vector['value']}"
    temporal_text += " #{unit}" if unit?
    temporal_text

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

class @bonnie.Value
  constructor: (value) ->
    @type = value['type']
    @unit = value['unit']
    @value = value['value']

@bonnie.template = (id, object={}) =>
  $("#bonnie_tmpl_#{id}").tmpl(object)

class Page
  constructor: (data_criteria, measure_period) ->
    bonnie.builder = new bonnie.Builder(data_criteria, measure_period)

  initialize: () =>
    $(document).on('click', '#dataCriteria .paramGroup', bonnie.builder.toggleDataCriteriaTree)
    $('.nav-tabs li').click((element) -> $('#workspace').empty() if !$(element.currentTarget).hasClass('active') )
