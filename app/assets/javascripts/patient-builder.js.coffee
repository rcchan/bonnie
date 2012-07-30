###
  remove birthdate, gender, expired, clinical trial
  create unique from specific/non specific occurrences
  add time, values, fields, negation
  save new patient
###

bonnie = @bonnie || {}

class @bonnie.PatientBuilder
  constructor: (data_criteria, value_sets) ->
    @data_criteria = {}
    @selected_data_criteria = {}
    @value_sets = {}
    @value_sets[s.oid] = s for s in value_sets
    @data_criteria_counter = 0
    for key in _.keys(data_criteria)
      @data_criteria[key] = new bonnie.DataCriteria(key, data_criteria[key], @measure_period)
  
  nextDataCriteriaId: =>
    @data_criteria_counter+=1
    
  registerDataCriteria: (criteria) =>
    criteria.start_date = $('#measure_period_start').val()
    criteria.end_date = $('#measure_period_start').val()
    criteria.start_time = '12:00 AM'
    criteria.end_time = '12:00 AM'
    @selected_data_criteria[criteria.id] = criteria
    @updateTimeline()
    
  detachDataCriteria: (criteria) =>
    $('.paramGroup[data-criteria-id='+criteria.id+']').detach();
    delete @selected_data_criteria[criteria.id]
    $('#workspace').empty();
    @updateTimeline()

  getDate: (date, time) =>
    new Date(Date.parse("#{date} #{time}"))
    
  getDateString: (date, time) =>
    d = @getDate(date, time)
    val = "#{d.getFullYear()}-#{@fillZeros(d.getMonth()+1)}-#{@fillZeros(d.getDate())}T#{@fillZeros(d.getHours())}:#{@fillZeros(d.getMinutes())}:#{@fillZeros(d.getSeconds())}Z"
    val
  
  fillZeros: (string) ->
    val = "0#{string}"
    val.substring(val.length-2)
  
  toggleDataCriteriaTree: (element) =>
    $(element.currentTarget).closest(".paramGroup").find("i").toggleClass("icon-chevron-right").toggleClass("icon-chevron-down")
    category = $(element.currentTarget).data('category');
    children = $(".#{category}_children")
    if (children.is(':visible'))
      children.hide("blind", { direction: "vertical" }, 500)
    else
      children.show("blind", { direction: "vertical" }, 500)

  timelineToDataCriteria: (data_criteria) =>
    bonnie.timeline.getBand(0).setCenterVisibleDate(Timeline.DateTime.parseGregorianDateTime(@getDateString(data_criteria.start_date, data_criteria.start_time)))
    
  highlightSelectedDataCriteria: (minDate, maxDate) =>
    container = $('#patient_data_criteria');
    children = container.children("div");
#    $('.paramGroup').removeClass('highlight')
    $('.paramItem').removeClass('highlight')
    for child in children
      dc = @selectedDataCriteria($(child).data('criteria-id'))
      dc_start = @getDate(dc.start_date, dc.start_time)
      dc_end = @getDate(dc.end_date, dc.end_time)
      if ((dc_start <= maxDate and dc_end >= minDate ))
        $(child).children('.paramItem').addClass('highlight')
      

  editDataCriteria: (element) =>
    leaf = $(element)

    $('.paramItem').removeClass('editing')
    leaf.children('.paramItem').addClass('editing')

    top = $('#workspace > div').css('top')
    $('#workspace').empty()
    data_criteria = @selectedDataCriteria($(element).data('criteria-id'))
    element = data_criteria.asHtml('data_criteria_edit').appendTo('#workspace')

    offset = leaf.offset().top + leaf.height()/2 - $('#workspace').offset().top - element.height()/2
    offset = 0 if offset < 0
    maxoffset = $('#measureEditContainer').height() - element.outerHeight(true) - $('#workspace').position().top - $('#workspace').outerHeight(true) + $('#workspace').height()+$('#patient_data_criteria').position().top
    offset = maxoffset if offset > maxoffset
    element.css("top", offset)
    arrowOffset = leaf.offset().top + leaf.height()/2 - element.offset().top - $('.arrow-w').outerHeight()/2
    arrowOffset = 0 if arrowOffset < 0
    $('.arrow-w').css('top', arrowOffset)
    element.css("top", top)
    element.animate({top: offset})
    $('.close_edit').click( -> $('#workspace').empty(); $('.paramItem').removeClass('editing') );
    $('#element_start_date').val(data_criteria.start_date);
    $('#element_end_date').val(data_criteria.end_date);
    
    $('#element_start_date').datepicker({
      onSelect: (selectedDate) -> $( "#element_end_date" ).datepicker( "option", "minDate", selectedDate )
    });
    $('#element_end_date').datepicker({
      onSelect: (selectedDate) -> $( "#element_start_date" ).datepicker( "option", "maxDate", selectedDate )
    });

    $('#element_start_time').timepicker();
    $('#element_end_time').timepicker();
    $('#element_start_time').val(data_criteria.start_time);
    $('#element_end_time').val(data_criteria.end_time);
    $('#element_update').click(=>
      data_criteria = @selectedDataCriteria($('#element_id').val())
      data_criteria.start_date = $('#element_start_date').val()
      data_criteria.start_time = $('#element_start_time').val()
      data_criteria.end_date = $('#element_end_date').val()
      data_criteria.end_time = $('#element_end_time').val()
      @updateTimeline()
      @timelineToDataCriteria(data_criteria);
      $('#workspace').empty()
      $('.paramItem').removeClass('editing')
      )

  sortSelectedDataCriteria: () =>
    container = $('#patient_data_criteria');
    children = container.children("div");

    children.detach().sort((left, right) =>
      left_dc = @selectedDataCriteria($(left).data('criteria-id'))
      right_dc = @selectedDataCriteria($(right).data('criteria-id'))
      @getDateString(left_dc.start_date, left_dc.start_time) > @getDateString(right_dc.start_date, right_dc.start_time) ? 1 : -1;
      );
    container.append(children);

    

  updateTimeline: =>
    
    @sortSelectedDataCriteria()
    
    timelineData = {
    'dateTimeFormat': 'iso8601',
    'events' : []
    }
    
    for key in _.keys(@selected_data_criteria)
      criteria = @selectedDataCriteria(key)
      start = @getDateString(criteria.start_date, criteria.start_time)
      end = @getDateString(criteria.end_date, criteria.end_time)
      event = {'start': start, 'title': "#{criteria.category} #{criteria.status}: #{criteria.title}", 'description': "#{criteria.category} #{criteria.status}: criteria.title"}
      event['end'] = end if start != end
      timelineData.events.push(event)
    
    bonnie.timelineEvents.clear();
    bonnie.timelineEvents.loadJSON(timelineData, '.'); 
    bonnie.timeline.layout()
    
  

  dataCriteria: (id) =>
    @data_criteria[id]
  selectedDataCriteria: (id) =>
    @selected_data_criteria[id]

class PatientBuilderPage
  constructor: (data_criteria, value_sets) ->
    bonnie.patientBuilder = new bonnie.PatientBuilder(data_criteria, value_sets)

  initialize: () =>
    $(document).on('click', '#dataCriteria .paramGroup', bonnie.patientBuilder.toggleDataCriteriaTree)
