controllers.DetailCtrl = ($scope, $rootScope, $http, $timeout, I18nFactory, mapStateService, edibleTypesService)->
  console.log "Detail Ctrl"

  reset = ()->
    console.log "RESETTING LOCATION"
    $scope.location = {}
    $scope.location_id = null
    $scope.reviews = []
    reset_review()

  reset_review = ()->
    $scope.location.observation = {quality_rating: "-1", yield_rating: "-1", fruiting: "-1"}

  reset()

  load_location = (id)->
    $http.get urls.location + id + ".json"
    .success (data)->
      # Distance
      latlng = new google.maps.LatLng(data.lat, data.lng)
      data.map_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.map_obj.getCenter()))
      if window.FFApp.current_position
        data.current_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.current_position))

      # Tags
      data.season_string = I18nFactory.season_string(data.season_start, data.season_stop, data.no_season)
      data.access_string = I18nFactory.short_access_types[data.access]

      # Types (unique)
      data.type_ids = _.uniq(data.type_ids)
      $scope.location = data
      $scope.location_id = data.id

      # Refresh map
      # sort of hacky--manually call the map directive function with just one location worth of data
      window.add_marker({title: data["title"], lat: data["lat"], lng: data["lng"], location_id: data["id"], types: data["type_ids"]})
      console.log "Added marker to map"
      console.log "DATA", data

  # Pull in useful things from i18n factory
  $scope.short_access_types = I18nFactory.short_access_types
  $scope.ratings = I18nFactory.ratings
  $scope.fruiting_status = I18nFactory.fruiting_status
  $scope.edible_types_data = edibleTypesService.data

  $scope.selected_review_source_type = ()->
    return "Edible Type"

  $scope.selected_review_access_type = ()->
    return "Access type"

  $scope.selected_location_access_type = ()->
    return "Access type"

  $scope.selected_location_source_type = ()->
    return "Edible Type"

  $scope.update_photo_list = ()->
    if navigator.camera?
      navigator.camera.getPicture ((photo_data)->
        $scope.location.observation.photo_data =
          data: photo_data
          #name: ?
          #type: ?
        console.log("Processed photo")
      ), (->
        console.log("Failed to get photo")
      ),
        quality: 50
        destinationType: Camera.DestinationType.DATA_URL
    else
      console.log("No camera attached to this device...")

  $scope.$on "BACKBUTTON", ()->
    console.log "Caught BACKBUTTON event in controller"
    if $scope.show_detail == true
      console.log "In Detail so going back"
      $scope.menu_left_btn_click()

  $scope.$on "SHOW-LOCATION", (event, id)->
    console.log "SHOW-LOCATION Broadcast CAUGHT", id
    $scope.show_detail = true
    $scope.location_id = id
    load_location(id)
    $scope.detail_context = "view_location"
    $scope.menu_title = "Location"

  $scope.$on "ADD-LOCATION", (event)->
    console.log "ADD-LOCATION Broadcast CAUGHT"
    $scope.show_detail = true
    $scope.detail_context = "add_location"
    $scope.menu_title = "Add location"
    $scope.location_id = null
    if window.FFApp.map_initialized == true
      center = window.FFApp.map_obj.getCenter()
      $scope.location.lat = center.lat()
      $scope.location.lng = center.lng()
    else
      console.log "ERROR: Map not initialized!"

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
          background_url = "url('img/png/no-image.png')"

        item.style =
          "background-image": background_url

      $scope.reviews = data

  $scope.save_review = ()->
    mapStateService.setLoading("Saving...")
    console.log("Location: ", $scope.location)
    # Since index = -1 implies undefined, we need to unset these before saving
    # Edit copy of observation to avoid changing view
    observation = angular.copy($scope.location.observation)
    if observation.quality_rating == "-1"
      observation.quality_rating = null
    if observation.yield_rating == "-1"
      observation.yield_rating = null
    if observation.fruiting == "-1"
      observation.fruiting = null

    $http.post urls.add_review($scope.location.id), observation: observation
    .success (data)->
      console.log("ADDED")
      console.log(data)
      $scope.location_id = $scope.location.id
      load_location($scope.location.id)
      mapStateService.removeLoading()
      $scope.detail_context = "view_location"
    .error (data)->
      console.log("ADD FAILED")
      console.log(data)
      $scope.detail_context = "view_location"

  $scope.save_location = ()->
    mapStateService.setLoading("Saving...")
    console.log("Location: ", $scope.location)

    if !$scope.location.id?
      # Since index = -1 implies undefined, we need to unset these before saving
      # Edit copy of observation to avoid changing view
      observation = angular.copy($scope.location.observation)
      if observation.quality_rating == "-1"
        observation.quality_rating = null
      if $scope.location.observation.yield_rating == "-1"
        observation.yield_rating = null
      if $scope.location.observation.fruiting == "-1"
        observation.fruiting = null
      $scope.location.observation = observation
      $http.post urls.add_location, location: $scope.location
      .success (data)->
        console.log("ADDED")
        console.log(data)
        $scope.location_id = data.id
        load_location(data.id)
        mapStateService.removeLoading()
        $scope.menu_title = "Location"
        $scope.detail_context = "view_location"
      .error (data)->
        console.log("ADD FAILED")
        console.log(data)
        $rootScope.$broadcast "SHOW-MAP"
    else
      $http.put urls.edit_location($scope.location.id), location: $scope.location
      .success (data)->
        console.log("UPDATED")
        console.log(data)
        load_location($scope.location_id)
        mapStateService.removeLoading()
        $scope.menu_title = "Location"
        $scope.detail_context = "view_location"
      .error (data)->
        console.log("UPDATE FAILED")
        console.log(data)
        $rootScope.$broadcast "SHOW-MAP"

  $scope.add_review = (id)->
    reset_review() # Ensures that sliders are in left-most (null) position
    $scope.detail_context = 'add_review'
    $scope.menu_title = "Add review"

  $scope.menu_left_btn_click = ()->
    # FIXME: add_review can be reached from view_location and view_reviews
    if $scope.detail_context == "edit_location" or $scope.detail_context == "add_review" or $scope.detail_context == "view_reviews"
      $scope.menu_title = "Location"
      $scope.detail_context = "view_location"
    else
      $scope.show_detail = false
      $scope.location_id = undefined
      $timeout reset, 500 # Smoother animation
    # For Android backbutton: wait until next digest loop, then update view
    $timeout(()->
      $scope.$apply()
    )
