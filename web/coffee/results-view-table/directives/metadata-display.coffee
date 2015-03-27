angular.module('GlycReSoftMSMSGlycopeptideResultsViewApp').directive "metadataDisplay",

    ["colorService", (colorService)->
        displayPolicy = {
            constant_modifications: {
                display: true
                includeUrl: "templates/modification-list.html"
            }
            variable_modifications: {
                display: true
                includeUrl: "templates/modification-list.html"
            }
            site_list: {
                display: true
                includeHtml: "{{content}}"
            }

        }
        return {
            restrict: "E"
            scope: {
                metadata: "="
            }
            templateUrl: "templates/metadata-display.html"
            link: (scope, element, attrs) ->
                scope.policy = displayPolicy
                scope.getColor = colorService.getColor
                console.log scope
        }]
