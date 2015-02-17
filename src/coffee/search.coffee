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

  $scope.update_position = ()->
    navigator.geolocation.getCurrentPosition ((position)-> 
      console.log("position obtained!")
      window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude,position.coords.longitude) 
      w = 69
      h = 69
      if window.FFApp.position_marker is `undefined`
        window.FFApp.position_marker = new google.maps.Marker(
          icon:
            url: "img/png/control-me.png"
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
        //window.FFApp.map_obj.setZoom window.FFApp.defaultZoom
    ), ()->
      console.log("Failed to get position")

  $scope.show_detail = (location_id)-> 
    $rootScope.$broadcast "SHOW-DETAIL", location_id

  $scope.logout = -> 
    $rootScope.$broadcast "LOGGED-OUT"
    $scope.show_menu = false
    

