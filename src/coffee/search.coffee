controllers.SearchCtrl = ($scope, $rootScope, $http, $location, AuthFactory)->
  console.log "Search Ctrl"

  $scope.current_view = "list" # or map
  $scope.show_menu = false

  $scope.map =
    center: 
      latitude: 45
      longitude: -73
    zoom: 8


  list_params = 
    lat: "39.991106"
    lng: "-105.247455"

  load_list = ()->
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

  load_view = ()->
    load_list()

  $rootScope.$on "LOGGED-IN", load_view

  load_view() if AuthFactory.is_logged_in()

  $scope.show_detail = (location_id)-> 
    $rootScope.$broadcast "SHOW-DETAIL", location_id

  $scope.logout = -> 
    $rootScope.$broadcast "LOGGED-OUT"
    $scope.show_menu = false
    

