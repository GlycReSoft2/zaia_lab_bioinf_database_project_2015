# help-menu.coffee
# Handles loading the help menu


angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").directive "helpMenu", ["$modal", ($modal) ->
    return {
        link: (scope, element, attrs) ->
            console.log("Help", arguments)
            element.click ->
                modalInstance = $modal.open({
                        templateUrl: 'templates/help-text.html',
                        size: 'lg'
                    })
    }
]