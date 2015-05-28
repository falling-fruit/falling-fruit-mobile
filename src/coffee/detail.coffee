controllers.DetailCtrl = ($scope, $rootScope, $http, $timeout, I18nFactory)->
  console.log "Detail Ctrl"

  document.addEventListener("backbutton", $scope.menu_left_btn_click, false)

  reset = ()->
    $scope.location = {}
    $scope.current_location = null
    $scope.current_review = null
    $scope.reviews = []
    $http.get urls.source_types
    .success (data)->
      $scope.source_types = data
      $scope.source_types_by_id = {}
      for row in data
        $scope.source_types_by_id[row.id]  = row

  reset()

  load_location = (id)->
    $http.get urls.location + id + ".json"
    .success (data)->
      latlng = new google.maps.LatLng(data.lat, data.lng)
      data.map_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.map_obj.getCenter()))
      if window.FFApp.current_position
        data.current_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.current_position))
      data.season_string = I18nFactory.season_string(data.season_start, data.season_stop, data.no_season)
      data.access_string = I18nFactory.short_access_types[data.access]
      $scope.location = data
      console.log "DATA", data

  # Pull in useful things from i18n factory
  $scope.short_access_types = I18nFactory.short_access_types
  $scope.ratings = I18nFactory.ratings
  $scope.fruiting_status = I18nFactory.fruiting_status

  $scope.selected_review_source_type = ()->
    return "Source Type"

  $scope.selected_review_access_type = ()->
    return "Access Type"

  $scope.selected_location_access_type = ()->
    return "Access Type"

  $scope.selected_location_source_type = ()->
    return "Source Type"

  $rootScope.$on "SHOW-DETAIL", (event, id)->
    console.log "SHOW-DETAIL Broadcast Event Handler", id
    $scope.show_detail = true
    #This can be called from 'Add Location' or 'List View' to view Location. Be careful
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
    $scope.detail_context = 'view_reviews'
    $scope.menu_title = 'Reviews'
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
    console.log($scope.location)
    if $scope.location.id isnt defined
      $http.post urls.add_location, location: $scope.location
        .success (data)->
          console.log("ADDED")
          console.log(data)
          $scope.location_id = data.id
          load_location(data.id)
          $scope.detail_context = "view_location"
        .failure (data)->
          console.log("ADD FAILED")
          console.log(data)
          $rootScope.$broadcast "SHOW-MAP"
    else
      $http.put urls.edit_location, location: $scope.location
        .success (data)->
          console.log("UPDATED")
          console.log(data)
          $scope.location_id = data.id
          load_location(data.id)
          $scope.detail_context = "view_location"
        .failure (data)->
          console.log("UPDATE FAILED")
          console.log(data)
          $rootScope.$broadcast "SHOW-MAP" 

  $scope.add_review = (id)->
    $scope.detail_context = 'add_review'
    $scope.menu_title = 'Add Review'
    
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
