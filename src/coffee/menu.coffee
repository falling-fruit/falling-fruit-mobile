controllers.MenuCtrl = ($scope, $rootScope, $http, $location)->
  console.log "Menu Ctrl"
  
  # Map type
  $scope.mapTypeId = window.FFApp.defaultMapTypeId
  $scope.$watch("mapTypeId", (newValue, oldValue)->
    if newValue != oldValue
      switch $scope.mapTypeId
        when 'roadmap' then window.FFApp.map_obj.setMapTypeId('roadmap')
        when 'terrain' then window.FFApp.map_obj.setMapTypeId('terrain')
        when 'hybrid' then window.FFApp.map_obj.setMapTypeId('hybrid')
        else console.log('Unknown mapTypeId selected')
  )
  
  # Map layers
  # FIXME: Change to radio selector (since can't really work together)
  bicycleLayer = new google.maps.BicyclingLayer()
  transitLayer = new google.maps.TransitLayer()
  trafficLayer = new google.maps.TrafficLayer()
  $scope.bicycle = false
  $scope.transit = false
  $scope.traffic = false
  $scope.toggle_bicycle = ()->
    if $scope.bicycle
      bicycleLayer.setMap(null)
    else
      bicycleLayer.setMap(window.FFApp.map_obj)
    $scope.bicycle = not $scope.bicycle
    
  $scope.toggle_transit = ()->
    if $scope.transit
      transitLayer.setMap(null)
    else
      transitLayer.setMap(window.FFApp.map_obj)  
    $scope.transit = not $scope.transit
    
  $scope.toggle_traffic = ()->
    if $scope.traffic
      trafficLayer.setMap(null)
    else
      trafficLayer.setMap(window.FFApp.map_obj)
    $scope.traffic = not $scope.traffic