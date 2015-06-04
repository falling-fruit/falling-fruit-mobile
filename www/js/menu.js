controllers.MenuCtrl = function($scope, $rootScope, $http, $location) {
  var bicycleLayer, transitLayer;
  console.log("Menu Ctrl");
  $scope.mapTypeId = window.FFApp.defaultMapTypeId;
  $scope.toggle_terrain = function() {
    if ($scope.mapTypeId === 'terrain') {
      $scope.mapTypeId = 'roadmap';
    } else {
      $scope.mapTypeId = 'terrain';
    }
    return window.FFApp.map_obj.setMapTypeId($scope.mapTypeId);
  };
  $scope.toggle_hybrid = function() {
    if ($scope.mapTypeId === 'hybrid') {
      $scope.mapTypeId = 'roadmap';
    } else {
      $scope.mapTypeId = 'hybrid';
    }
    return window.FFApp.map_obj.setMapTypeId($scope.mapTypeId);
  };
  $scope.layer = null;
  bicycleLayer = new google.maps.BicyclingLayer();
  $scope.toggle_bicycle = function() {
    if ($scope.layer === 'bicycle') {
      bicycleLayer.setMap(null);
      $scope.layer = null;
    } else {
      bicycleLayer.setMap(window.FFApp.map_obj);
      $scope.layer = 'bicycle';
    }
    return transitLayer.setMap(null);
  };
  transitLayer = new google.maps.TransitLayer();
  $scope.toggle_transit = function() {
    if ($scope.layer === 'transit') {
      transitLayer.setMap(null);
      $scope.layer = null;
    } else {
      transitLayer.setMap(window.FFApp.map_obj);
      $scope.layer = 'transit';
    }
    return bicycleLayer.setMap(null);
  };
  $scope.muni = window.FFApp.muni;
  $scope.toggle_muni = function() {
    window.FFApp.muni = !window.FFApp.muni;
    $scope.muni = window.FFApp.muni;
    window.clear_markers();
    window.do_markers();
    if ($scope.current_view === "list") {
      return $scope.load_list();
    } else {
      return $scope.list_center = null;
    }
  };
  $scope.metric = window.FFApp.metric;
  $scope.toggle_metric = function() {
    window.FFApp.metric = !window.FFApp.metric;
    return $scope.metric = window.FFApp.metric;
  };
  return $scope.logout = function() {
    $rootScope.$broadcast("LOGGED-OUT");
    return $scope.show_menu = false;
  };
};
