# fragment-ion.coffee
# Directives for presenting Oxonium Ions, backbone Ions and Stub Ions

fragmentIon = (GlycReSoftMSMSGlycopeptideResultsViewApp.directive "fragmentIon",
 () ->
    return {
        restrict: "AE",
        template: "<p class='fragment-ion-tag'><b>PPM Error</b>: {{fragment_ion.ppm_error|number:2}} &nbsp; <b>Key</b>: {{fragment_ion.key}}</p>"
            })
