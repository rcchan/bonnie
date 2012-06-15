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
  execute_measure(patient)
  
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
  for p in patient
    do (p) ->      
      # name = p.first + " " + p.last
      execute_measure(p)
      # console.log(emitted)

  for e in emitted
    do (e) ->
      # select the row with the patient id
      row = $('#patients_' + e.patient_id).parent().parent()
    
      # example of selecting row elements
      # $(row).find(':input[type=checkbox]').attr("checked", false)
    
      # TODO: this is not DRY
      if e.population == true
        cell = $(row).children(":nth-child(2)")
        cell.css('background-color', '#EEE')      #light gray
        cell.html('&#x2713;')
      
      if e.denominator == true
        cell = $(row).children(":nth-child(3)")
        cell.css('background-color', '#99CCFF')   #light blue
        cell.html('&#x2713;')
      
      if e.numerator == true
        cell = $(row).children(":nth-child(4)")
        cell.css('background-color', '#CCFFCC')   #light green
        cell.html('&#x2713;')

      if e.exclusions == true
        cell = $(row).children(":nth-child(5)")
        cell.css('background-color', '#FFCC99')   #light orange
        cell.html('&#x2713;')
  
  # tally up totals
  