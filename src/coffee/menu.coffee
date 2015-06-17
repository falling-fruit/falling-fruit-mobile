controllers.MenuCtrl = ($scope, $rootScope, $http, $location, I18nFactory, AuthFactory)->
  console.log "Menu Ctrl"

  ## Map type
  $scope.mapTypeId = window.FFApp.defaultMapTypeId

  # Terrain
  $scope.toggle_terrain = ()->
    if $scope.mapTypeId == 'terrain'
      $scope.mapTypeId = 'roadmap'
    else
      $scope.mapTypeId = 'terrain'
    window.FFApp.map_obj.setMapTypeId($scope.mapTypeId)

  # Satellite
  $scope.toggle_hybrid = ()->
    if $scope.mapTypeId == 'hybrid'
      $scope.mapTypeId = 'roadmap'
    else
      $scope.mapTypeId = 'hybrid'
    window.FFApp.map_obj.setMapTypeId($scope.mapTypeId)

  ## Map layers
  $scope.layer = null

  # Bicycle
  bicycleLayer = new google.maps.BicyclingLayer()
  $scope.toggle_bicycle = ()->
    if $scope.layer == 'bicycle'
      bicycleLayer.setMap(null)
      $scope.layer = null
    else
      bicycleLayer.setMap(window.FFApp.map_obj)
      $scope.layer = 'bicycle'
    transitLayer.setMap(null)

  # Transit
  transitLayer = new google.maps.TransitLayer()
  $scope.toggle_transit = ()->
    if $scope.layer == 'transit'
      transitLayer.setMap(null)
      $scope.layer = null
    else
      transitLayer.setMap(window.FFApp.map_obj)
      $scope.layer = 'transit'
    bicycleLayer.setMap(null)

  ## Filters
  # FIXME: Share fun/var with map directive in a cleaner fashion that using window?

  $scope.muni = window.FFApp.muni
  $scope.toggle_muni = ()->
    window.FFApp.muni = not window.FFApp.muni
    $scope.muni = window.FFApp.muni
    window.clear_markers()
    window.do_markers()
    if $scope.current_view == "list"
      $scope.load_list()
    else
      $scope.list_center = null
  
  $scope.selectedType = window.FFApp.selectedType
  $http.get urls.source_types
  .success (data)->
    $scope.source_types = data
    $scope.source_types_by_id = {}
    for row in data
      $scope.source_types_by_id[row.id]  = row
  $scope.filter_types = ()->
    window.FFApp.selectedType = $scope.selectedType
    window.clear_markers()
    window.do_markers()
    if $scope.current_view == "list"
      $scope.load_list()
    else
      $scope.list_center = null
  $scope.reset_filter_types = () ->
    $scope.selectedType = null
    $scope.filter_types()
  
  ## Regional
  
  $scope.metric = window.FFApp.metric
  $scope.toggle_metric = ()->
    window.FFApp.metric = not window.FFApp.metric
    $scope.metric = window.FFApp.metric
    # Force update distance strings in displayed list
    if $scope.current_view == "list" and $scope.list_items
      for item in $scope.list_items
        item.distance_string = I18nFactory.distance_string(item.distance)

  # Logout
  $scope.logout = ()->
    AuthFactory.handleLoggedOut() #Formerly Broadcast "LOGGED-OUT"