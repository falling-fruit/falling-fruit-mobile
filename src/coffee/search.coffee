controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory)->
  console.log "Search Ctrl"

  $scope.current_view = "map" # or map
  $scope.show_menu = false
  $scope.search_text = ''

  $scope.load_list = ()->
    # FIXME: currently a bit of lag while this loads, could add a spinner or re-use
    # data from the map's update markers call
    if window.FFApp.map_obj == undefined
      return
    latlng = window.FFApp.map_obj.getCenter()
    list_params = 
      lat: latlng.lat()
      lng: latlng.lng()
    $http.get urls.nearby , params: list_params
    .success (data)->   
      for item in data
        if item.hasOwnProperty("photos") and item.photos[0][0].thumbnail.indexOf("missing.png") == -1
          background_url = "url('#{item.photos[0][0].thumbnail}')"
        else
          background_url = "url('../img/png/no-image.png')"

        item.style = 
          "background-image": background_url

      $scope.list_items = data
      $scope.current_view = "list"

  $rootScope.$on "MAP-LOADED", $scope.update_position
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
    # Run geocoder for everything else
    window.FFApp.geocoder.geocode { 'address': $scope.search_text }, (results, status) ->
      if status == google.maps.GeocoderStatus.OK
        bounds = results[0].geometry.viewport
        latlng = results[0].geometry.location
        window.FFApp.map_obj.fitBounds bounds
      else
        console.log("Failed to do geocode") # FIXME: replace with common error handling
    $scope.current_view = "map"

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
        )
      else
        window.FFApp.position_marker.setPosition window.FFApp.current_position
      
      window.FFApp.map_obj.panTo window.FFApp.current_position
      window.FFApp.map_obj.setZoom 15
      
    ), ()->
      console.log("Failed to get position") # FIXME: replace with common error handling

  $scope.show_detail = (location_id)-> 
    $rootScope.$broadcast "SHOW-DETAIL", location_id

  $scope.logout = -> 
    $rootScope.$broadcast "LOGGED-OUT"
    $scope.show_menu = false
    

