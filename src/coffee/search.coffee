controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory, I18nFactory, mapStateService)->
  console.log "Search Ctrl"

  $scope.current_view = "map"
  $scope.show_menu = false
  $scope.add_location = false
  $scope.search_text = ''
  $scope.mapStateData = mapStateService.data

  ## Map
  $scope.show_map = ()->
    if $scope.current_view != "map"
      $scope.current_view = "map"

  ## List
  $scope.list_center = null
  $scope.$watch("list_center", (newValue, oldValue)->
    if newValue != oldValue
      if $scope.current_view == "list"
        $scope.load_list($scope.list_center)
  )

  $scope.show_list = ()->
    if $scope.current_view != "list"
      $scope.current_view = "list"
      $scope.list_center = window.FFApp.map_obj.getCenter()

  $scope.load_list = (center)->
    mapStateService.setLoading("Loading...")
    $scope.targeted = false
    $scope.add_location = false

    if !center
      center = window.FFApp.map_obj.getCenter()

    if window.FFApp.muni
      muni = 1
    else
      muni = 0

    bounds = window.FFApp.map_obj.getBounds()
    list_params =
      lat: center.lat()
      lng: center.lng()
      nelat: bounds.getNorthEast().lat()
      nelng: bounds.getNorthEast().lng()
      swlat: bounds.getSouthWest().lat()
      swlng: bounds.getSouthWest().lng()
      muni: muni

    $http.get urls.nearby, params: list_params
    .success (data)->
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

  $scope.begin_add_location = ()->
    console.log "Begin add location"
    $scope.add_location = true
    $scope.current_view = "map"

  $scope.cancel_add_location = ()->
    console.log "Cancel add location"
    $scope.add_location = false

  $scope.update_position = ()->

    # Position
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

      # Heading
      # (degrees clockwise from North)
      # FIXME: Actually retrieve heading
      heading = Math.floor(Math.random() * 359)
      if heading
        if !window.FFApp.heading_marker
          heading_icon_inner =
            path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
            fillColor: '#FF8A22'
            fillOpacity: 1
            strokeWeight: 0
            scale: 4
            rotation: heading
            anchor: new google.maps.Point(0, 2.6)
          heading_icon_outer =
            path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
            fillColor: '#1C95F2'
            fillOpacity: 1
            strokeWeight: 0
            scale: 4
            rotation: heading
            anchor: new google.maps.Point(0, 7.75)
          window.FFApp.heading_marker = new google.maps.Marker(
            icon: heading_icon_outer
            position: window.FFApp.current_position
            map: window.FFApp.map_obj
            draggable: false
            clickable: false
            zIndex: 100
          )
          window.FFApp.heading_marker.bindTo('position', window.FFApp.position_marker, 'position')
        else
          icon = window.FFApp.heading_marker.getIcon()
          icon.rotation = heading
          window.FFApp.heading_marker.setIcon(icon)

    ), ()->
      console.log("Failed to get position") # FIXME: replace with common error handling
  
  $scope.$on "SHOW-DETAIL", (event, id)->
    console.log "SHOW-DETAIL caught in search controller", id    
    
  ## Info Window / Add Location
  $scope.show_detail = (location_id)->
    if location_id or $scope.add_location
      $scope.add_location = false
      $rootScope.$broadcast "SHOW-DETAIL", location_id
