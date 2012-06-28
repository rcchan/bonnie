# log to a div
append_div = (div, message) ->
  div.append(message)
  div.append('\n')

# function for measures/debug view
debug_js_load = () ->
  # reusable selectors
  code_element = $('.CodeRay')
  log_element = $('#log')
  
  code_element.hide()
  execute_measure(patient[0])
  
  for e in emitted[0].logger
    do (e) ->
      append_div(log_element, e)
  
  $("#run_numerator_link").click (event) ->
    event.preventDefault()  # don't follow link, TODO: UJS route and fallback
    Logger.logger = [] if Logger?
    log_element.empty()
    patient_api = new hQuery.Patient(patient);
    hqmfjs.NUMER(patient_api)
    for e in Logger.logger
      do (e) ->
        append_div(log_element, e)
        
  $('#run_denominator_link').click (event) ->
    event.preventDefault()  # don't follow link, TODO: UJS route and fallback
    Logger.logger = [] if Logger?
    log_element.empty()
    patient_api = new hQuery.Patient(patient);
    hqmfjs.DENOM(patient_api)
    for e in Logger.logger
      do (e) ->
        append_div(log_element, e)

  $('#toggle_code_link').click (event) ->
    if (code_element.is(":visible") == true)
      code_element.hide()
      log_element.show()
    else
      code_element.show()
      log_element.hide()

populate_test_table = () ->
  # column totals
  population_total = 0
  denominator_total = 0
  numerator_total = 0
  exclusions_total = 0
  
  for p in patient
    do (p) ->      
      execute_measure(p)

  for e in emitted
    do (e) ->
      # select the row with the patient id
      row = $('#patients_' + e.patient_id).parent().parent()
    
      # TODO: this is not DRY
      # colorize and checkmark table cells based on results
      if e.population == true
        population_total += 1
        cell = $(row).children(":nth-child(2)")
        cell.css('background-color', '#EEE')      #light gray
        cell.html('&#x2713;')
      
      if e.denominator == true
        denominator_total += 1
        cell = $(row).children(":nth-child(3)")
        cell.css('background-color', '#99CCFF')   #light blue
        cell.html('&#x2713;')
      
      if e.numerator == true
        numerator_total += 1
        cell = $(row).children(":nth-child(4)")
        cell.css('background-color', '#CCFFCC')   #light green
        cell.html('&#x2713;')

      if e.exclusions == true
        exclusions_total += 1
        cell = $(row).children(":nth-child(5)")
        cell.css('background-color', '#FFCC99')   #light orange
        cell.html('&#x2713;')
  
  # set total columns
  total_row = $('#patients').find('.total').find('.span2')
  total_row.eq(1).html(population_total)
  total_row.eq(2).html(denominator_total)
  total_row.eq(3).html(numerator_total)
  total_row.eq(4).html(exclusions_total)

# add row highlighting when rolling over inspect link
bind_inspect_highlight = () ->
  # select all rows with the inspect link only
  $('#patients .inspect:contains("inspect")').hover(
    -> $(this).parent().css('background-color', '#f5f5f5'),
    -> $(this).parent().css('background-color', 'white')
  )

# keep track of jquery bbq population criteria state and update test button href
test_button_bbq = (e) ->
  # save test button element for later, we will change a url parameter in the button href
  test_button = $('#pageButtons .btn').eq(1)
  
  # split on ? in case we already have updated the href
  base_url = test_button.attr('href').split("?")[0]
  
  # regex to find the population criteria number selected in the dropdown
  definition_number_matches = e.match /.*\/(\d+)\/definition/
  if definition_number_matches
    population_criteria_number = definition_number_matches[1]
  else
    population_criteria_number = 0
  population_criteria_number++     # off by one fix
  
  # console.log("population_criteria_number: " + population_criteria_number)

  # make button link pass a url param
  test_button.attr('href', base_url + "?population_criteria=" + population_criteria_number)
  # console.log(test_button.attr('href'))
