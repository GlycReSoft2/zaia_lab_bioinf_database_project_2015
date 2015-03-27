# html-popover.coffee
# A shim for providing HTML content to Angular Bootstrap UI Popovers

# Data Binding:
# Put content in popover-html-unsafe=""
# Put click, focus, or hover in popover-trigger=""
# Put a direction in popover-placement=""

angular.module('GlycReSoftMSMSGlycopeptideResultsViewApp')
    .directive("popoverHtmlUnsafePopup",  () ->
      console.log("Init Popover Directive", arguments)
      return {
        restrict: "EA",
        replace: true,
        scope: { title: "@", content: "@", placement: "@", animation: "&", isOpen: "&"},
        template: '<div class="popover {{placement}}" ng-class="{ in: isOpen(), fade: animation() }">
  <div class="arrow"></div>

  <div class="popover-inner">
      <h3 class="popover-title" ng-bind="title" ng-show="title"></h3>
      <div class="popover-content" bind-html-unsafe="content"></div>
  </div>
</div>'
      }
    )
    .directive("popoverHtmlUnsafe", [ "$tooltip", ($tooltip) ->
      console.log("Init Inner Popover Directive", arguments)
      return $tooltip("popoverHtmlUnsafe", "popover", "click");
    ])
