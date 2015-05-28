controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory, I18nFactory, mapStateService)->
  console.log "Search Ctrl"

  $scope.current_view = "map"
  $scope.show_menu = false
  $scope.show_add_location = false
  $scope.search_text = ''
  $scope.targeted = false
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
    mapStateService.setLoading("Loading List...")
    $scope.targeted = false
    $scope.show_add_location = false

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
          background_url = "url('../img/png/no-image.png')"

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

  $scope.close_add_location = ()->
    #Instead of pullin up the add location dialog to stop just close this
    console.log "Close Add Location"
    window.FFApp.target_marker.setMap(null)
    window.FFApp.target_marker = null
    $scope.targeted = false #reset targeted
    $scope.show_add_location = false

  $scope.update_position = ()->
    navigator.geolocation.getCurrentPosition ((position)->
      console.log("position obtained!")
      window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude,position.coords.longitude)
      w = 40
      h = 40
      if window.FFApp.position_marker is `undefined`
        window.FFApp.position_marker = new google.maps.Marker(
          icon:
            url: "img/png/map-me-40.png"
            size: new google.maps.Size(w, h)
            origin: new google.maps.Point(0, 0)

            # by convention, icon center is at ~40%
            anchor: new google.maps.Point(w * 0.4, h * 0.4)

          position: window.FFApp.current_position
          map: window.FFApp.map_obj
          title: "Current Position"
          draggable: false
          zIndex: 100
        )
      else
        window.FFApp.position_marker.setPosition window.FFApp.current_position

      window.FFApp.map_obj.panTo window.FFApp.current_position
      window.FFApp.map_obj.setZoom window.FFApp.map_obj.getZoom()
      $scope.list_center = window.FFApp.current_position

    ), ()->
      console.log("Failed to get position") # FIXME: replace with common error handling

  ## Info Window / Add Location
  $scope.show_detail = (location_id)->
    ## Has the '.add-location' btn been clicked or is this a view location_id call?
    if $scope.targeted || location_id

      if window.FFApp.target_marker
         window.FFApp.target_marker.setMap(null)
         window.FFApp.target_marker = null
         $scope.targeted = false #reset targeted
         $scope.show_add_location = false

      $rootScope.$broadcast "SHOW-DETAIL", location_id
    else
      # show target icon on map
      if !window.FFApp.target_marker? #is `undefined`
        $scope.show_add_location = true
        window.FFApp.target_marker = new google.maps.Marker(
          icon:
            url: "img/png/transparent.png"
            size: new google.maps.Size(58, 75)
            origin: new google.maps.Point(0, 0)

            # by convention, icon center is at ~40%
            anchor: new google.maps.Point(58 * 0.4, 75 * 0.4)

          position: window.FFApp.map_obj.getCenter()
          map: window.FFApp.map_obj
          title: "Target New Point"
          draggable: true
        )
        window.FFApp.target_marker.bindTo('position', window.FFApp.map_obj, 'center');
      $scope.targeted = true
