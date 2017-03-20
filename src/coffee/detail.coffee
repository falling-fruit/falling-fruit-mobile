controllers.DetailCtrl = ($scope, $rootScope, $http, $timeout, I18nFactory, mapStateService, edibleTypesService, $translate, moment)->
  console.log "Detail Ctrl"

  reset = ()->
    console.log "RESETTING LOCATION"
    $scope.location = {}
    $scope.location_copy = {}
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

      # Types (unique)
      data.type_ids = _.uniq(data.type_ids)
      $scope.location = data
      $scope.location_id = data.id

      console.log "DATA", data

  # Pull in useful things from i18n factory
  $scope.short_access_types = I18nFactory.short_access_types
  $scope.ratings = I18nFactory.ratings
  $scope.fruiting_status = I18nFactory.fruiting_status
  $scope.edible_types_data = edibleTypesService.data
  $scope.translate = $translate

  $scope.update_photo_list = ()->
    navigator.camera.getPicture (photo_data) ->
      $scope.location.observation.photo_data =
        data: photo_data
        #name: ?
        #type: ?
      console.log("Processed photo")
    , (message)->
      console.log("Failed to get photo: " + message)
    ,
      sourceType: Camera.PictureSourceType.CAMERA
      encodingType: Camera.EncodingType.JPEG
      quality: 75
      targetWidth: 1440
      targetHeight: 1440
      correctOrientation: true
      allowEdit: false
      #FIXME: Save to photo album not working on Android
      saveToPhotoAlbum: true
      #TODO: Give user choice to select from Camera.PictureSourceType.PHOTOLIBRARY
      mediaType: Camera.MediaType.PICTURE
      cameraDirection: Camera.Direction.BACK
      destinationType: Camera.DestinationType.DATA_URL

  $scope.$on "BACKBUTTON", ()->
    console.log "Caught BACKBUTTON event in controller"
    if $scope.show_detail == true
      console.log "In Detail so going back"
      $scope.menu_left_btn_click()

  $scope.$on "SHOW-LOCATION", (event, id)->
    console.log "SHOW-LOCATION Broadcast: ", id
    $scope.show_detail = true
    $scope.location_id = id
    load_location(id)
    $scope.detail_context = "view_location"

  $scope.$on "ADD-LOCATION", (event)->
    console.log "ADD-LOCATION Broadcast CAUGHT"
    $scope.show_detail = true
    $scope.detail_context = "add_location"
    $scope.location_id = null
    if window.FFApp.map_initialized == true
      center = window.FFApp.map_obj.getCenter()
      $scope.location.lat = center.lat()
      $scope.location.lng = center.lng()
    else
      console.log "ERROR: Map not initialized!"

  $scope.show_reviews = ()->
    $scope.detail_context = 'view_reviews'
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
    mapStateService.setLoading("status_message.saving")
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

  $scope.paramsForLocation = (location) ->
    {
      lat: location.lat,
      lng: location.lng,
      description: location.description,
      access: location.access,
      fruiting: location.observation.fruiting,
      yield_rating: location.observation.yield_rating,
      quality_rating: location.observation.quality_rating,
      type_ids: (location.type_ids || []).join(",")
    }

  $scope.save_location = ()->
    mapStateService.setLoading("status_message.saving")
    console.log("Saving Location: ", $scope.location)

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

      params = $scope.paramsForLocation($scope.location)

      $http.post urls.add_location, params
        .success (data) ->
          console.log("ADDED LOCATION", data.id)
          console.log(data)
          $scope.location_id = data.id
          load_location(data.id)
          mapStateService.removeLoading()
          $scope.detail_context = "view_location"
        .error (data) ->
          console.log("ADD LOCATION FAILED")
          console.log(data)
          $rootScope.$broadcast "SHOW-MAP"
    else
      $http.put urls.edit_location($scope.location.id), location: $scope.location
      .success (data)->
        console.log("UPDATED LOCATION")
        console.log(data)
        load_location($scope.location_id)
        mapStateService.removeLoading()
        $scope.detail_context = "view_location"
      .error (data)->
        console.log("UPDATE LOCATION FAILED: ", $scope.location.id)
        console.log(data)
        $rootScope.$broadcast "SHOW-MAP"

  $scope.add_review = (id)->
    reset_review() # Ensures that sliders are in their left-most position
    $scope.detail_context = "add_review"

  $scope.edit_location = (id)->
    $scope.detail_context = "edit_location"

  $scope.menu_left_btn_click = ()->
    # FIXME: add_review can be reached from view_location and view_reviews
    if $scope.detail_context == "edit_location" or $scope.detail_context == "add_review" or $scope.detail_context == "view_reviews"
      $scope.detail_context = "view_location"
      load_location($scope.location_id)
    else
      $scope.show_detail = false
      $scope.location_id = undefined
      $timeout reset, 500 # Smoother animation
    # For Android backbutton: wait until next digest loop, then update view
    $timeout(()->
      $scope.$apply()
    )

  # HACK (Android/iOS): Force blur on any active element when sliders are clicked
  $scope.blurActiveElement = ()->
    document.activeElement.blur()

  # Update menu title
  # view_location, edit_location, add_location
  # view_reviews, add_review
  $scope.menu_title = null
  # Context change
  $scope.$watch('detail_context', (newValue, oldValue, $scope)->
    $translate("menu." + newValue).then((string)->
      $scope.menu_title = string
    )
  )
  # Language change
  $rootScope.$on '$translateChangeSuccess', ->
    $translate("menu." + $scope.detail_context).then((string)->
      $scope.menu_title = string
    )

  # Helper functions

  # Check if object is undefined, empty, or has only blank values
  $scope.is_empty = (obj)->
    return typeof(obj) == "undefined" || obj.length == 0 || Object.values(obj).every((x)->
      return ["-1", -1, "", null, undefined].indexOf(x) > -1
     )

  # Used for showing otherwise disabled features
  $scope.hostname = window.location.hostname
