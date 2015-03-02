# resizeable.coffee
# Makes the element re-size to some percentage of the total window size.
# Currently only deals with the height of the element.
resizeable = GlycReSoftMSMSGlycopeptideResultsViewApp.directive 'resizable', ($window) ->
    {
        restrict: "A"
        link:(scope, element, attr) ->
                console.log "Resizeable", arguments
                windowPercent = scope.percent
                scope.initializeWindowSize = ->
                  scope.windowHeight = $window.innerHeight * windowPercent
                  scope.windowWidth  = $window.innerWidth
                  element.css("height", scope.windowHeight + "px")

                scope.initializeWindowSize()

                angular.element($window).bind 'resize', ->
                  scope.initializeWindowSize()
                  scope.$apply()
    }