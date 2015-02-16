controllers.SearchCtrl = function($scope, $rootScope, $http, $location, AuthFactory) {
  var list_params, load_list, load_view;
  console.log("Search Ctrl");
  $scope.current_view = "list";
  $scope.show_menu = false;
  $scope.map = {
    center: {
      latitude: 45,
      longitude: -73
    },
    zoom: 8
  };
  list_params = {
    lat: "39.991106",
    lng: "-105.247455"
  };
  load_list = function() {
    return $http.get(urls.nearby, {
      params: list_params
    }).success(function(data) {
      var background_url, item, _i, _len;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        item = data[_i];
        if (item.hasOwnProperty("photos") && item.photos[0][0].thumbnail.indexOf("missing.png") === -1) {
          background_url = "url('" + item.photos[0][0].thumbnail + "')";
        } else {
          background_url = "url('../img/png/no-image.png')";
        }
        item.style = {
          "background-image": background_url
        };
      }
      return $scope.list_items = data;
    });
  };
  load_view = function() {
    return load_list();
  };
  $rootScope.$on("LOGGED-IN", load_view);
  if (AuthFactory.is_logged_in()) {
    load_view();
  }
  $scope.show_detail = function(location_id) {
    return $rootScope.$broadcast("SHOW-DETAIL", location_id);
  };
  return $scope.logout = function() {
    $rootScope.$broadcast("LOGGED-OUT");
    return $scope.show_menu = false;
  };
};
