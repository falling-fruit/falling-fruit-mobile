controllers.DetailCtrl = ($scope, $rootScope, $http, $location)->
  console.log "Detail Ctrl"  

  $rootScope.$on "SHOW-DETAIL", ()->
    $scope.show_detail = true
    $scope.detail_context = "add"
    $scope.menu_title = "Add"

  $scope.menu_left_btn_click = ()->
    $scope.show_detail = false