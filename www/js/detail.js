controllers.DetailCtrl = function($scope, $rootScope, $http, $timeout, I18nFactory) {
  var load_location, reset;
  console.log("Detail Ctrl");
  document.addEventListener("backbutton", $scope.menu_left_btn_click, false);
  reset = function() {
    $scope.location = {};
    $scope.current_location = null;
    $scope.current_review = null;
    $scope.reviews = [];
    return $http.get(urls.source_types).success(function(data) {
      var row, _i, _len, _results;
      $scope.source_types = data;
      $scope.source_types_by_id = {};
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        row = data[_i];
        _results.push($scope.source_types_by_id[row.id] = row);
      }
      return _results;
    });
  };
  reset();
  load_location = function(id) {
    return $http.get(urls.location + id + ".json").success(function(data) {
      var latlng;
      latlng = new google.maps.LatLng(data.lat, data.lng);
      data.map_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.map_obj.getCenter()));
      if (window.FFApp.current_position) {
        data.current_distance = I18nFactory.distance_string(google.maps.geometry.spherical.computeDistanceBetween(latlng, window.FFApp.current_position));
      }
      data.season_string = I18nFactory.season_string(data.season_start, data.season_stop, data.no_season);
      data.access_string = I18nFactory.short_access_types[data.access];
      $scope.location = data;
      return console.log("DATA", data);
    });
  };
  $scope.short_access_types = I18nFactory.short_access_types;
  $scope.ratings = I18nFactory.ratings;
  $scope.fruiting_status = I18nFactory.fruiting_status;
  $scope.selected_review_source_type = function() {
    return "Source Type";
  };
  $scope.selected_review_access_type = function() {
    return "Access Type";
  };
  $scope.selected_location_access_type = function() {
    return "Access Type";
  };
  $scope.selected_location_source_type = function() {
    return "Source Type";
  };
  $rootScope.$on("SHOW-DETAIL", function(event, id) {
    var center;
    console.log("SHOW-DETAIL Broadcast Event Handler", id);
    $scope.show_detail = true;
    if (id === void 0) {
      $scope.detail_context = "add_location";
      $scope.menu_title = "Add";
      if (window.FFApp.map_initialized === true) {
        center = window.FFApp.map_obj.getCenter();
        $scope.location.lat = center.lat();
        return $scope.location.lng = center.lng();
      }
    } else {
      $scope.location_id = id;
      load_location(id);
      $scope.detail_context = "view_location";
      return $scope.menu_title = "Location";
    }
  });
  $scope.show_reviews = function() {
    $scope.detail_context = 'view_reviews';
    $scope.menu_title = 'Reviews';
    return $http.get(urls.reviews($scope.location.id)).success(function(data) {
      var background_url, item, _i, _len;
      console.log("REVIEWS", data);
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        item = data[_i];
        if (item.hasOwnProperty("photo_url") && item.photo_url !== null && item.photo_url.indexOf("missing.png") === -1) {
          background_url = "url('" + item.photo_url + "')";
        } else {
          background_url = "url('../img/png/no-image.png')";
        }
        item.style = {
          "background-image": background_url
        };
      }
      return $scope.reviews = data;
    });
  };
  $scope.save_location = function() {
    console.log($scope.location);
    if ($scope.location.id !== defined) {
      return $http.post(urls.add_location, {
        location: $scope.location
      }).success(function(data) {
        console.log("ADDED");
        console.log(data);
        $scope.location_id = data.id;
        load_location(data.id);
        return $scope.detail_context = "view_location";
      }).failure(function(data) {
        console.log("ADD FAILED");
        console.log(data);
        return $rootScope.$broadcast("SHOW-MAP");
      });
    } else {
      return $http.put(urls.edit_location, {
        location: $scope.location
      }).success(function(data) {
        console.log("UPDATED");
        console.log(data);
        $scope.location_id = data.id;
        load_location(data.id);
        return $scope.detail_context = "view_location";
      }).failure(function(data) {
        console.log("UPDATE FAILED");
        console.log(data);
        return $rootScope.$broadcast("SHOW-MAP");
      });
    }
  };
  $scope.add_review = function(id) {
    if (id !== void 0) {
      $scope.current_review = _.findWhere($scope.reviews, {
        id: id
      });
      console.log("CR", $scope.current_review);
      $scope.menu_title = "Edit review";
    } else {
      $scope.current_review = DetailFactory.get_new_review_model();
      $scope.menu_title = "Add review";
    }
    return $scope.detail_context = "add_review";
  };
  return $scope.menu_left_btn_click = function() {
    if ($scope.detail_context === "add_review") {
      $scope.detail_context = "view_reviews";
      return $scope.menu_title = "Reviews";
    } else if ($scope.detail_context === "view_reviews") {
      $scope.detail_context = "view_location";
      return $scope.menu_title = "Location";
    } else if ($scope.detail_context === "add_location") {
      if ($scope.location_id === void 0) {
        $scope.show_detail = false;
        return $scope.location_id = void 0;
      } else {
        $scope.detail_context = "view_location";
        return $scope.menu_title = "Location";
      }
    } else if ($scope.detail_context === "view_location") {
      $timeout(reset, 500);
      $scope.show_detail = false;
      return $scope.location_id = void 0;
    }
  };
};
