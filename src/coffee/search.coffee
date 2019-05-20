controllers.SearchCtrl = ($scope, $rootScope, $http, $location, $timeout, AuthFactory, I18nFactory, mapStateService, edibleTypesService, $swipe, $translate)->
  console.log "Search Ctrl"

  $scope.current_view = "map"
  $scope.show_menu = false
  $scope.add_location_controls = false
  $scope.search_text = ''
  $scope.mapStateData = mapStateService.data
  $scope.authStateData = AuthFactory.data

  ## Map
  $scope.show_map = ()->
    if $scope.current_view != "map"
      $scope.current_view = "map"

  $scope.zoom_map = (dz)->
    window.FFApp.map_obj.setZoom(window.FFApp.map_obj.getZoom() + dz)

  ## List
  $scope.list_bounds = null
  $scope.$watch("list_bounds", (newValue, oldValue)->
    if $scope.current_view == "list"
      if newValue != oldValue
        $scope.load_list($scope.list_bounds)
  )
  $scope.reset_list = ()->
    if $scope.current_view == "list"
      $scope.load_list()
    else
      $scope.list_bounds = null

  $scope.show_list = ()->
    if $scope.current_view != "list"
      $scope.current_view = "list"
      $scope.list_bounds = window.FFApp.map_obj.getBounds()

  $scope.load_list = (bounds)->
    console.log("LOADING LIST")
    mapStateService.setLoading("status_message.loading_list")
    $scope.targeted = false
    $scope.add_location_controls = false
    center = window.FFApp.map_obj.getCenter()

    if !bounds
      bounds = window.FFApp.map_obj.getBounds()

    list_params =
      lat: center.lat()
      lng: center.lng()
      nelat: bounds.getNorthEast().lat()
      nelng: bounds.getNorthEast().lng()
      swlat: bounds.getSouthWest().lat()
      swlng: bounds.getSouthWest().lng()

    if window.FFApp.muni
      list_params.muni = 1
    else
      list_params.muni = 0

    list_params.t = window.FFApp.selectedType.id unless window.FFApp.selectedType is null
    list_params.c = window.FFApp.cats unless window.FFApp.cats is null

    $http.get urls.nearby, params: list_params
    .success (data)->
      # FIXME: Type filtering of list by id not possible.
      if window.FFApp.selectedType
        selectedTypeName = window.FFApp.selectedType.name.split(" [")[0]
        _.remove data, (n)->
          not _.contains(n["title"].split(RegExp(', | & ')), selectedTypeName)

      for item in data
        if item.hasOwnProperty("photos") and item.photos[0][0].thumbnail.indexOf("missing.png") == -1
          background_url = "url('#{item.photos[0][0].thumbnail}')"
        else
          background_url = "url('img/png/no-image.png')"

        item.distance_string = I18nFactory.distance_string(item.distance)
        item.style =
          "background-image": background_url

      $scope.list_items = data
      mapStateService.removeLoading()
      $scope.list_bounds = bounds

  ## Side menu
  $scope.toggleSideMenu = ()->
    AuthFactory.toggleSideMenu()

  ## Position
  #$rootScope.$on "LOGGED-IN", load_view
  #load_view() if AuthFactory.is_logged_in()

  # HACK (Android): Force blur on search input when map is touched
  $scope.blurSearchInput = ()->
    if (document.activeElement.id == "searchInput")
      document.activeElement.blur()

  $scope.location_search = ()->
    # If it looks like "lat, lng" just go there
    strsplit = $scope.search_text.split(/[\s,]+/)
    if strsplit.length == 2
      lat = parseFloat(strsplit[0])
      lng = parseFloat(strsplit[1])
      if !isNaN(lat) and !isNaN(lng)
        latlng = new (google.maps.LatLng)(lat, lng)
        window.FFApp.map_obj.setZoom 17
        window.FFApp.map_obj.panTo latlng
        $scope.reset_list()
    # Run geocoder for everything else
    window.FFApp.geocoder.geocode { 'address': $scope.search_text }, (results, status) ->
      if status == google.maps.GeocoderStatus.OK
        bounds = results[0].geometry.viewport
        latlng = results[0].geometry.location
        window.FFApp.map_obj.fitBounds bounds
        $scope.reset_list()
      else
        console.log("Failed to do geocode") # FIXME: replace with common error handling

  ## Add location

  $scope.begin_add_location = ()->
    console.log "Begin add location"
    $scope.add_location_controls = true
    $scope.current_view = "map"

  $scope.cancel_add_location = ()->
    console.log "Cancel add location"
    $scope.add_location_controls = false

  $scope.confirm_add_location = ()->
    console.log "Confirm add location"
    $scope.add_location_controls = false
    $rootScope.$broadcast "ADD-LOCATION"

  ## Show location

  $scope.show_location = (location_id)->
    $rootScope.$broadcast "SHOW-LOCATION", location_id

  # FIXME: Once list and map share same data, highlight location by z-index / color
  # Avoid recentering map since this resets map and list
  $scope.show_location_on_map = (location_id)->
    $scope.current_view = "map"
    $http.get urls.location + location_id + ".json"
    .success (data)->
      latlng = new (google.maps.LatLng)(data.lat, data.lng)
      window.FFApp.map_obj.panTo(latlng)

  ## Watch position

  $scope.trackPosition = true
  $scope.watchPositionID = null
  $scope.centerChangeListener = null
  watchPositionOptions =
    enableHighAccuracy: true
    timeout: 10000 # 10 seconds in milliseconds
    maximumAge: 3000 # milliseconds

  $scope.watchHeadingID = null
  watchHeadingOptions =
    frequency: 200 # milliseconds

  clear_position_watching = ()->
    console.log("STOP Watching position")
    window.FFApp.position_marker.setVisible(false)
    navigator.geolocation.clearWatch($scope.watchPositionID)
    google.maps.event.removeListener($scope.centerChangeListener)
    $scope.watchPositionID = null
    window.FFApp.current_position = null

  clear_heading_watching = ()->
    console.log("STOP Watching heading")
    window.FFApp.heading_marker.setVisible(false)
    navigator.compass.clearWatch($scope.watchHeadingID)
    $scope.watchHeadingID = null

  $scope.toggle_position_watching = ()->
    # Position
    if $scope.watchPositionID
      clear_position_watching()
      if (mapStateService.data.message == "Locating you")
        mapStateService.removeLoading()
    else
      console.log("START Watching position")
      $scope.trackPosition = true
      mapStateService.setLoading("status_message.locating_you")
      $scope.watchPositionID = navigator.geolocation.watchPosition(watch_position, (error)->
        console.log("ERROR Watching position: ", error)
        # Falling Fruit would like to use your current position: Don't allow | Allow
        # Turn on location services to allow Falling Fruit to determine your position: Settings | Cancel
        # FIXME: Android device returns TIMEOUT even if location services are off
        if error.code == error.PERMISSION_DENIED
          mapStateService.setLoading("status_message.position_denied")
        else # Position unavailable or timeout
          mapStateService.setLoading("status_message.position_unavailable")
        $scope.$apply() # HACK: Force digest cycle to update loading message from within callback.
        $timeout () ->
          mapStateService.removeLoading()
        , 5000

        # Clear the watch positioning
        clear_position_watching()
        if $scope.watchHeadingID
          clear_heading_watching()

      , watchPositionOptions)

    # Heading
    if $scope.watchHeadingID
      clear_heading_watching()
    else if navigator.compass
      console.log("START Watching heading")
      $scope.watchHeadingID = navigator.compass.watchHeading(watch_heading, (error)->
        console.log("ERROR Watching heading:", error)
        clear_heading_watching()
      , watchHeadingOptions)

  $scope.recenter_map = ()->
    if window.FFApp.current_position == null
      return
    if window.FFApp.map_idle
      window.FFApp.map_obj.panTo(window.FFApp.current_position)
      $scope.reset_list()
      if !$scope.trackPosition
        $scope.trackPosition = true
        listen_for_map_center_change()
    else
      # Wait until idle, in case map is panning
      google.maps.event.addListenerOnce(window.FFApp.map_obj, "idle", ()->
        $scope.recenter_map()
      )

  listen_for_map_center_change = ()->
    google.maps.event.addListenerOnce(window.FFApp.map_obj, "dragstart", ()->
      console.log("Map center changed: dragstart")
      $scope.trackPosition = false
      # Make the recenter button appear immediately:
      $scope.$apply()
    )
    google.maps.event.addListenerOnce(window.FFApp.map_obj, "dblclick", ()->
      console.log("Map center changed: dblclick")
      $scope.trackPosition = false
      # Make the recenter button appear immediately:
      $scope.$apply()
    )

  # TODO: Smoother transitions with sliding window averaging?
  watch_position = (position)->
    console.log("Position watched: ", position);

    # Set current position based on distance between old and new positions
    old_position = window.FFApp.current_position
    new_position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
    window.FFApp.position_accuracy = position.coords.accuracy # meters
    $scope.movedFarEnough = true

    if old_position == null
      window.FFApp.current_position = new_position
    else
      distance_moved = google.maps.geometry.spherical.computeDistanceBetween(old_position, new_position)
      # TODO: Use old and new position accuracy to dynamically set threshold?
      if distance_moved < 2 # meters (smartphone GPS max accuracy ~ 2 meters)
        $scope.movedFarEnough = false
      else
        window.FFApp.current_position = new_position

    # If position changed enough, move marker
    if $scope.movedFarEnough
      console.log("Position updated");
      window.FFApp.position_marker.setPosition(window.FFApp.current_position)
      # And if map is tracking position, recenter map and reset list
      if $scope.trackPosition
        $scope.recenter_map()

    # Either way, make position marker visible and update accuracy marker
    if !window.FFApp.position_marker.getVisible()
      window.FFApp.position_marker.setVisible(true)
    window.FFApp.accuracy_marker.setRadius(window.FFApp.position_accuracy)

    # If loading message is showing, hide it
    if mapStateService.data.isLoading
      mapStateService.removeLoading()
      # HACK: To close loading message from inside callback, force digest cycle
      $scope.$apply()

    # If first callback, add map drag listener
    if old_position == null
      listen_for_map_center_change()

  watch_heading = (heading)->
    console.log("Heading watched: ", heading);

    # Determine heading
    old_heading = window.FFApp.current_heading
    new_heading = heading.trueHeading
    if new_heading < 0
      new_heading = heading.magneticHeading
    if Math.abs(old_heading - new_heading) > 2 # degrees
      console.log("Heading updated");
      # Update marker
      icon = window.FFApp.heading_marker.getIcon()
      icon.rotation = new_heading
      window.FFApp.heading_marker.setIcon(icon)
      window.FFApp.current_heading = new_heading

    # Don't show heading marker until position marker is visible
    if !window.FFApp.heading_marker.getVisible() && window.FFApp.position_marker.getVisible()
      window.FFApp.heading_marker.setVisible(true)

  # Type select
  # NOTE: Moved from side menu controller because of CSS limitation
  # (position: fixed relative to transformed parent element, not viewport)
  $scope.onTypeChange = (type)->
    window.FFApp.selectedType = type
    window.clear_markers()
    window.do_markers()
    $scope.reset_list()
