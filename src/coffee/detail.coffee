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
      $scope.location = data
      console.log "DATA", data

  $scope.location_access_types = [
    "Added by owner"
    "Permitted by owner"
    "Public"
    "Private but overhanging"
    "Private"
  ]

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





    
    


