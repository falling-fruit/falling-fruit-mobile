controllers.SearchCtrl = function($scope, $rootScope, $http, $location, AuthFactory, I18nFactory, mapStateService) {
  console.log("Search Ctrl");
  $scope.current_view = "map";
  $scope.show_menu = false;
  $scope.show_add_location = false;
  $scope.search_text = '';
  $scope.targeted = false;
  $scope.mapStateData = mapStateService.data;
  $scope.show_map = function() {
    if ($scope.current_view !== "map") {
      return $scope.current_view = "map";
    }
  };
  $scope.list_center = null;
  $scope.$watch("list_center", function(newValue, oldValue) {
    if (newValue !== oldValue) {
      if ($scope.current_view === "list") {
        return $scope.load_list($scope.list_center);
      }
    }
  });
  $scope.show_list = function() {
    if ($scope.current_view !== "list") {
      $scope.current_view = "list";
      return $scope.list_center = window.FFApp.map_obj.getCenter();
    }
  };
  $scope.load_list = function(center) {
    var bounds, list_params, muni;
    mapStateService.setLoading("Loading List...");
    $scope.targeted = false;
    $scope.show_add_location = false;
    if (!center) {
      center = window.FFApp.map_obj.getCenter();
    }
    if (window.FFApp.muni) {
      muni = 1;
    } else {
      muni = 0;
    }
    bounds = window.FFApp.map_obj.getBounds();
    list_params = {
      lat: center.lat(),
      lng: center.lng(),
      nelat: bounds.getNorthEast().lat(),
      nelng: bounds.getNorthEast().lng(),
      swlat: bounds.getSouthWest().lat(),
      swlng: bounds.getSouthWest().lng(),
      muni: muni
    };
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
        item.distance_string = I18nFactory.distance_string(item.distance);
        item.style = {
          "background-image": background_url
        };
      }
      $scope.list_items = data;
      return mapStateService.removeLoading();
    });
  };
  $scope.location_search = function() {
    var lat, latlng, lng, strsplit;
    strsplit = $scope.search_text.split(/[\s,]+/);
    if (strsplit.length === 2) {
      lat = parseFloat(strsplit[0]);
      lng = parseFloat(strsplit[1]);
      if (!isNaN(lat) && !isNaN(lng)) {
        latlng = new google.maps.LatLng(lat, lng);
        window.FFApp.map_obj.setZoom(17);
        window.FFApp.map_obj.panTo(latlng);
        $scope.list_center = latlng;
      }
    }
    return window.FFApp.geocoder.geocode({
      'address': $scope.search_text
    }, function(results, status) {
      var bounds;
      if (status === google.maps.GeocoderStatus.OK) {
        bounds = results[0].geometry.viewport;
        latlng = results[0].geometry.location;
        window.FFApp.map_obj.fitBounds(bounds);
        return $scope.list_center = latlng;
      } else {
        return console.log("Failed to do geocode");
      }
    });
  };
  $scope.close_add_location = function() {
    console.log("Close Add Location");
    window.FFApp.target_marker.setMap(null);
    window.FFApp.target_marker = null;
    $scope.targeted = false;
    return $scope.show_add_location = false;
  };
  $scope.update_position = function() {
    return navigator.geolocation.getCurrentPosition((function(position) {
      var h, w;
      console.log("position obtained!");
      window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      w = 40;
      h = 40;
      if (window.FFApp.position_marker === undefined) {
        window.FFApp.position_marker = new google.maps.Marker({
          icon: {
            url: "img/png/map-me-40.png",
            size: new google.maps.Size(w, h),
            origin: new google.maps.Point(0, 0),
            anchor: new google.maps.Point(w * 0.4, h * 0.4)
          },
          position: window.FFApp.current_position,
          map: window.FFApp.map_obj,
          title: "Current Position",
          draggable: false,
          zIndex: 100
        });
      } else {
        window.FFApp.position_marker.setPosition(window.FFApp.current_position);
      }
      window.FFApp.map_obj.panTo(window.FFApp.current_position);
      window.FFApp.map_obj.setZoom(window.FFApp.map_obj.getZoom());
      return $scope.list_center = window.FFApp.current_position;
    }), function() {
      return console.log("Failed to get position");
    });
  };
  return $scope.show_detail = function(location_id) {
    if ($scope.targeted || location_id) {
      if (window.FFApp.target_marker) {
        window.FFApp.target_marker.setMap(null);
        window.FFApp.target_marker = null;
        $scope.targeted = false;
        $scope.show_add_location = false;
      }
      return $rootScope.$broadcast("SHOW-DETAIL", location_id);
    } else {
      if (window.FFApp.target_marker == null) {
        $scope.show_add_location = true;
        window.FFApp.target_marker = new google.maps.Marker({
          icon: {
            url: "img/png/transparent.png",
            size: new google.maps.Size(58, 75),
            origin: new google.maps.Point(0, 0),
            anchor: new google.maps.Point(58 * 0.4, 75 * 0.4)
          },
          position: window.FFApp.map_obj.getCenter(),
          map: window.FFApp.map_obj,
          title: "Target New Point",
          draggable: true
        });
        window.FFApp.target_marker.bindTo('position', window.FFApp.map_obj, 'center');
      }
      return $scope.targeted = true;
    }
  };
};
