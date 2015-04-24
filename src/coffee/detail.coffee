controllers.DetailCtrl = ($scope, $rootScope, $http, $timeout)->
  console.log "Detail Ctrl"

  reset = ()->
    $scope.location = {}
    $scope.current_location = null
    $scope.current_review = null
    $scope.reviews = []
    $http.get urls.source_types
    .success (data)-> 
      $scope.source_types = data 

  reset()
  
  load_location = (id)->
    $http.get urls.location + id + ".json"
    .success (data)->
      latlng = new google.maps.LatLng(data.lat, data.lng)
      data.map_distance = google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.map_obj.getCenter())
      if window.FFApp.current_position
        data.current_distance = google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.current_position)
      data.season_string = $scope.season_string(data.season_start, data.season_stop, data.no_season)
      $scope.location = data
      console.log "DATA", data
      
  $scope.season_string = (season_start, season_stop, no_season)->
    if no_season
      season_start = 0
      season_stop = 11
    if season_start or season_stop
      return (if season_start.blank then $scope.months[season_start] else "?") + " - " + (if season_stop then $scope.months[season_stop] else "?")
    else
      return null
  
  $scope.short_access_types = [
    "Added by owner"
    "Permitted by owner"
    "Public"
    "Private but overhanging"
    "Private"
  ]
  
  $scope.months = [
    "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
  ]
  
  # Degrees to radians
  rad = (x)->
    return x * Math.PI / 180
  
  # Distance between points (meters)
  distance = (p1, p2)->
    R = 6378137;
    dlat = rad(p2.lat() - p1.lat())
    dlng = rad(p2.lng() - p1.lng())
    a = Math.sin(dlat / 2) * Math.sin(dlat / 2) +
      Math.cos(rad(p1.lat())) * Math.cos(rad(p2.lat())) *
      Math.sin(dlng / 2) * Math.sin(dlng / 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    d = R * c
    return d
  
  $scope.selected_review_source_type = ()->
    return "Source Type"

  $scope.selected_review_access_type = ()->
    return "Access Type"

  $scope.selected_location_access_type = ()->
    return "Access Type"  

  $scope.selected_location_source_type = ()->
    return "Source Type"

  $rootScope.$on "SHOW-DETAIL", (event, id)->
    console.log "SHOW-DETAIL", id
    $scope.show_detail = true
    if id is undefined       
      $scope.detail_context = "add_location"
      $scope.menu_title = "Add"
      if window.FFApp.map_initialized == true
        center = window.FFApp.map_obj.getCenter()
        $scope.location.lat = center.lat()
        $scope.location.lng = center.lng()
    else
      $scope.location_id = id
      load_location(id)
      $scope.detail_context = "view_location"
      $scope.menu_title = "Location"

  $scope.show_reviews = ()->
    $scope.detail_context='view_reviews' 
    $scope.menu_title='Reviews'
    $http.get urls.reviews($scope.location.id)
    .success (data)->
      console.log "REVIEWS", data
      for item in data
        if item.hasOwnProperty("photo_url") and item.photo_url isnt null and item.photo_url.indexOf("missing.png") == -1
          background_url = "url('#{item.photo_url}')"
        else
          background_url = "url('../img/png/no-image.png')"

        item.style = 
          "background-image": background_url

      $scope.reviews = data      

  $scope.save_location = ()->
    # turn types string into an array if needed
    #if $scope.location.types != null and $scope.location.types.constructor == String
    #  $scope.location.types = [$scope.location.types]
    $http.post urls.add_location, location: $scope.location
    .success (data)->
      console.log("ADDED")
      $scope.location_id = data.id
      load_location(data.id)
      $scope.detail_context = "view_location"  
    .failure (data)->
      console.log("ADD FAILED")
      console.log(data)
      $rootScope.$broadcast "SHOW-MAP"

  $scope.add_review = (id)->
    if id isnt undefined
      $scope.current_review = _.findWhere($scope.reviews, id: id)
      console.log "CR", $scope.current_review      
      $scope.menu_title = "Edit Review"
    else
      $scope.current_review = DetailFactory.get_new_review_model()
      $scope.menu_title = "Add Review"

    $scope.detail_context = "add_review"
      
  $scope.menu_left_btn_click = ()->
    if $scope.detail_context == "add_review"
      $scope.detail_context = "view_reviews"
      $scope.menu_title = "Reviews"
    else if $scope.detail_context == "view_reviews"
      $scope.detail_context = "view_location"
      $scope.menu_title = "Location"
    else if $scope.detail_context == "add_location"
      if $scope.location_id is undefined
        $scope.show_detail = false
        $scope.location_id = undefined        
      else        
        $scope.detail_context = "view_location"
        $scope.menu_title = "Location"
    else if $scope.detail_context == "view_location"
      $timeout reset, 500        
      $scope.show_detail = false
      $scope.location_id = undefined





    
    


