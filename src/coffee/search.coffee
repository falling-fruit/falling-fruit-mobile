controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory)->
  console.log "Search Ctrl"

  $scope.current_view = "map"
  $scope.show_menu = false
  $scope.search_text = ''
  $scope.targeted = false

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
      # FIXME: show loading gif

  $scope.load_list = (center)->
    # FIXME: Slow. Re-use data from map update markers call (weighted towards map center?)
    if !center
      center = window.FFApp.map_obj.getCenter()
    if window.FFApp.muni
      muni = 1
    else
      muni = 0
    list_params =
      lat: center.lat()
      lng: center.lng()
      muni: muni
    $http.get urls.nearby, params: list_params
    .success (data)->
      for item in data
        if item.hasOwnProperty("photos") and item.photos[0][0].thumbnail.indexOf("missing.png") == -1
          background_url = "url('#{item.photos[0][0].thumbnail}')"
        else
          background_url = "url('../img/png/no-image.png')"

        item.style =
          "background-image": background_url

      $scope.list_items = data

  $scope.distance_string = (meters)->
    if window.FFApp.metric
      if meters < 1000
        return parseFloat((meters).toPrecision(2)) + " m"
      else
        return parseFloat((meters / 1000).toPrecision(2)) + " km"
    else
      feet = Math.round(meters / 0.3048)
      if feet < 1000
        return parseFloat((feet).toPrecision(2)) + " ft"
      else
        return parseFloat((feet / 5280).toPrecision(2)) + " mi"

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

  ## Infowindow

  $scope.show_detail = (location_id)->
    if $scope.targeted

      if window.FFApp.target_marker != null
         window.FFApp.target_marker.setMap(null)
         window.FFApp.target_marker = null
         $scope.targeted = false

      $rootScope.$broadcast "SHOW-DETAIL", location_id
    else
      # show target
      if window.FFApp.target_marker is `undefined`
        window.FFApp.target_marker = new google.maps.Marker(
          icon:
            url: "img/png/control-add.png"
            size: new google.maps.Size(58, 75)
            origin: new google.maps.Point(0, 0)

            # by convention, icon center is at ~40%
            anchor: new google.maps.Point(58 * 0.4, 75 * 0.4)

          position: window.FFApp.map_obj.getCenter()
          map: window.FFApp.map_obj
          title: "Target New Point"
          draggable: false
        )
        window.FFApp.target_marker.bindTo('position', window.FFApp.map_obj, 'center');
      $scope.targeted = true
