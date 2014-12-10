controllers.SearchCtrl = ($scope, $http, $location, uiGmapGoogleMapApi)->
  console.log "Search Ctrl"

  $scope.currentView = "map"

  $scope.map =
    center: 
      latitude: 45
      longitude: -73
    zoom: 8

  uiGmapGoogleMapApi.then (maps)->
    console.log "READY"