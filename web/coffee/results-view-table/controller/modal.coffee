ModalInstanceCtrl = ($scope, $modalInstance, title, items, summary, postLoadFn) ->
  $scope.title = title
  $scope.items = items
  $scope.summary = summary
  $scope.postLoadFn = postLoadFn

  $scope.ok = ->
    console.log $scope
    $modalInstance.close true

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
