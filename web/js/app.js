var GlycReSoftMSMSGlycopeptideResultsViewApp, registerDataChange;

GlycReSoftMSMSGlycopeptideResultsViewApp = angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp", ["ui.bootstrap", "ngGrid", "ngSanitize", "ui"]);

Array.prototype.sum = function() {
  var i, total, _i, _len;
  total = 0;
  for (_i = 0, _len = this.length; _i < _len; _i++) {
    i = this[_i];
    total += i;
  }
  return total;
};

Array.prototype.mean = function() {
  var total;
  total = this.sum();
  return total / this.length;
};

if (Number.isInteger == null) {
  Number.isInteger = function(nVal) {
    return typeof nVal === "number" && isFinite(nVal) && nVal > -9007199254740992 && nVal < 9007199254740992 && Math.floor(nVal) === nVal;
  };
}

registerDataChange = function(data, name, format) {
  var ctrl, ex, objects;
  format = (format === undefined ? "csv" : format);
  try {
    ctrl = angular.element("#classifier-results").scope();
    if (format === "csv") {
      objects = CsvService.setDefaultValues(CsvService.deserializeAfterParse(data));
    } else {
      if (format === "json") {
        objects = data;
      }
    }
    ctrl.$apply(function() {
      return ctrl.params.name = (name === undefined ? ctrl.params.name : name);
    });
    ctrl.update(objects);
    console.log(data);
  } catch (_error) {
    ex = _error;
    alert("An error occurred while injecting data: " + ex);
    console.log(ex);
  }
};
