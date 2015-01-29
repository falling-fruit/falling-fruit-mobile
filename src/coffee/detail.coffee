factories.DetailFactory = ()->
  props = 
    new_location_model: ()->
      return {}

    new_review_model: ()->
      return {}

  return props


controllers.DetailCtrl = ($scope, $rootScope, $http, $location)->
  console.log "Detail Ctrl"

  $scope.location = null
  $scope.current_review = null
  $scope.reviews = null

  load_location = (id)->
    $http.get urls.location + id + ".json"
    .success (data)->
      $scope.location = data
      console.log "DATA", data

  $rootScope.$on "SHOW-DETAIL", (event, id)->
    console.log "SHOW-DETAIL", id
    $scope.show_detail = true
    if id is undefined       
      $scope.detail_context = "add_location"
      $scope.menu_title = "Add"
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
      $scope.reviews = data
      console.log "DATA", data
      

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
      $scope.show_detail = false
      $scope.location_id = undefined





    
    