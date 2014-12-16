controllers.SearchCtrl = ($scope, $rootScope, $http, $location)->
  console.log "Search Ctrl"

  $scope.current_view = "map"
  $scope.show_menu = false

  $scope.map =
    center: 
      latitude: 45
      longitude: -73
    zoom: 8

  $scope.show_detail = -> $rootScope.$broadcast "SHOW-DETAIL"
    