# Angular Application Definition
GlycReSoftMSMSGlycopeptideResultsViewApp = angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp", [
    "ui.bootstrap",
    "ngGrid",
    "ngSanitize",
    "ui"
])

# Simple mathematics
Array::sum = ->
    total = 0
    for i in @
        total += i
    total

Array::mean = ->
    total = @sum()
    total / @length

# Number.isInteger is not implemented in IE
if not Number.isInteger?
    Number.isInteger = (nVal) ->
        typeof nVal is "number" and isFinite(nVal) and nVal > -9007199254740992 and
        nVal < 9007199254740992 and Math.floor(nVal) == nVal

registerDataChange = (data, name, format) ->
  format = (if format is `undefined` then "csv" else format)
  try
    ctrl = angular.element("#classifier-results").scope()
    if format is "csv"
      objects = CsvService.setDefaultValues(CsvService.deserializeAfterParse(data))
    else objects = data  if format is "json"

    ctrl.$apply( ->
      ctrl.params.name = (if name is `undefined` then ctrl.params.name else name)
    )
    ctrl.update objects
    console.log data
  catch ex
    alert "An error occurred while injecting data: " + ex
    console.log ex
  return