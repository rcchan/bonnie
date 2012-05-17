# log to a div
append_div = (div, message) ->
  div.append(message)
  div.append('\n')

# onload
$ ->
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
