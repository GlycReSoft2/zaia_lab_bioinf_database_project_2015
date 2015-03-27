# help-menu.coffee
# Handles loading the help menu when the ? button is clicked


angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").directive "helpMenu", ["$modal", ($modal) ->
    return {
        link: (scope, element, attrs) ->
            element.click ->
                modalInstance = $modal.open({
                        templateUrl: 'templates/help-text.html',
                        size: 'lg'
                    })
    }
]
