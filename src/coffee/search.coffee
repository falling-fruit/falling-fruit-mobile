controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory, I18nFactory, mapStateService, $swipe)->
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
  $scope.list_center = null
  $scope.reset_list_center = ()->
    $scope.list_center = null
  $scope.$watch("list_center", (newValue, oldValue)->
    if newValue != oldValue
      if $scope.current_view == "list"
        $scope.load_list($scope.list_center)
  )

  $scope.toggleSideMenu = ()->
    AuthFactory.toggleSideMenu()

  $scope.show_list = ()->
    if $scope.current_view != "list"
      $scope.current_view = "list"
      $scope.list_center = window.FFApp.map_obj.getCenter()

  $scope.load_list = (center)->
    mapStateService.setLoading("Loading...")
    $scope.targeted = false
    $scope.add_location_controls = false

    if !center
      center = window.FFApp.map_obj.getCenter()
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
      # FIXME: Type filtering of list by id not possible
      if window.FFApp.selectedType
        _.remove data, (n)->
          n["title"].split(RegExp(' , | & ')).indexOf(window.FFApp.selectedType.name.split(" [")[0]) < 0
          #n["types"].concat(n["parent_types"]).indexOf(window.FFApp.selectedType.id) < 0

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

  ## Position
  #$rootScope.$on "MAP-LOADED", $scope.update_position
  #$rootScope.$on "LOGGED-IN", load_view
  #load_view() if AuthFactory.is_logged_in()

  # HACK (Android): Force blur on search input when map is touched
  $scope.blurSearchInput = ()->
    console.log("blurred map!")
    if (document.activeElement.id == "searchInput")
      document.activeElement.blur()

  $scope.location_search = ()->
    # If it looks like a lat/lng just go there
    strsplit = $scope.search_text.split(/[\s,]+/)
    if strsplit.length == 2
      lat = parseFloat(strsplit[0])
      lng = parseFloat(strsplit[1])
      if !isNaN(lat) and !isNaN(lng)
        latlng = new (google.maps.LatLng)(lat, lng)
        window.FFApp.map_obj.setZoom 17
        window.FFApp.map_obj.panTo latlng
        $scope.list_center = latlng
    # Run geocoder for everything else
    window.FFApp.geocoder.geocode { 'address': $scope.search_text }, (results, status) ->
      if status == google.maps.GeocoderStatus.OK
        bounds = results[0].geometry.viewport
        latlng = results[0].geometry.location
        window.FFApp.map_obj.fitBounds bounds
        $scope.list_center = latlng
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

  ## Current position (update once)

  $scope.update_position = ()->
    # position
    navigator.geolocation.getCurrentPosition ((position)->
      console.log("Position obtained")
      window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
      window.FFApp.position_accuracy = position.coords.accuracy

      if !window.FFApp.position_marker
        window.FFApp.position_marker = new google.maps.Marker(
          icon:
            path: google.maps.SymbolPath.CIRCLE
            strokeColor: '#1C95F2'
            fillColor: '#FF8A22'
            fillOpacity: 1
            strokeWeight: 8
            scale: 8
          position: window.FFApp.current_position
          map: window.FFApp.map_obj
          draggable: false
          clickable: false
          zIndex: 100
        )
      else
        window.FFApp.position_marker.setPosition(window.FFApp.current_position)

      window.FFApp.map_obj.panTo(window.FFApp.current_position)
      $scope.list_center = window.FFApp.current_position

      # heading
      # FIXME: Always returns zero?
#       navigator.compass.getCurrentHeading ((heading)->
#         console.log("Heading obtained")
#         if !window.FFApp.heading_marker
#           heading_icon_inner =
#             path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
#             fillColor: '#FF8A22'
#             fillOpacity: 1
#             strokeWeight: 0
#             scale: 4
#             rotation: heading.trueHeading
#             anchor: new google.maps.Point(0, 2.6)
#           heading_icon_outer =
#             path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
#             fillColor: '#1C95F2'
#             fillOpacity: 1
#             strokeWeight: 0
#             scale: 4
#             rotation: heading.trueHeading
#             anchor: new google.maps.Point(0, 7.75)
#           window.FFApp.heading_marker = new google.maps.Marker(
#             icon: heading_icon_outer
#             position: window.FFApp.current_position
#             map: window.FFApp.map_obj
#             draggable: false
#             clickable: false
#             zIndex: 100
#           )
#           window.FFApp.heading_marker.bindTo('position', window.FFApp.position_marker, 'position')
#         else
#           icon = window.FFApp.heading_marker.getIcon()
#           icon.rotation = heading.trueHeading
#           window.FFApp.heading_marker.setIcon(icon)
#       ), ()->
#         console.log("Failed to get heading") # FIXME: replace with common error handling

    ), (err)->
      console.log("Failed to get position") # FIXME: replace with common error handling
      alert("Please enable location access in settings. Then we can find trees closer to you!")
    , {maximumAge: 3000, timeout: 4000, enableHighAccuracy: true}
      
  ## Current position (watch - unused)
  $scope.ignoreCenterChange = false
  # FIXME: Can't be called here (idea is to turn tracking off if map center is moved manually
#   google.maps.event.addListener window.FFApp.map_obj, "center_changed", ()->
#     if $scope.ignoreCenterChange
#       $scope.ignoreCenterChange = false
#     else if $scope.watchPositionID
#       navigator.geolocation.clearWatch($scope.watchPositionID)
#       $scope.watchPositionID = null

  $scope.watchPositionID = null
  watchPositionOptions =
    enableHighAccuracy: true
    timeout: 10000
    maximumAge: 3000

  $scope.toggle_position_tracking = ()->
    if $scope.watchPositionID
      navigator.geolocation.clearWatch($scope.watchPositionID)
      $scope.watchPositionID = null
    else
      $scope.watchPositionID = navigator.geolocation.watchPosition(watch_position, (->
        console.log("Failed to watch position")
      ), watchPositionOptions)

  watch_position = (position)->

    # position
    console.log("Position updated")
    window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
    window.FFApp.position_accuracy = position.coords.accuracy
    if !window.FFApp.position_marker
      window.FFApp.position_marker = new google.maps.Marker(
        icon:
          path: google.maps.SymbolPath.CIRCLE
          strokeColor: '#1C95F2'
          fillColor: '#FF8A22'
          fillOpacity: 1
          strokeWeight: 8
          scale: 8
        position: window.FFApp.current_position
        map: window.FFApp.map_obj
        draggable: false
        clickable: false
        zIndex: 100
      )
    else
      window.FFApp.position_marker.setPosition(window.FFApp.current_position)
    window.FFApp.ignoreCenterChange = true
    window.FFApp.map_obj.panTo(window.FFApp.current_position)
    $scope.list_center = window.FFApp.current_position
