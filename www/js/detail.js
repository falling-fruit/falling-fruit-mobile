factories.DetailFactory = function($http) {
  var props;
  props = {
    get_new_location_model: function() {
      return {};
    },
    get_new_review_model: function() {
      return {};
    },
    source_types: [],
    last_source_type_refresh: null,
    get_source_types: function() {
      return $http.get(urls.source_types).success(function(data) {
        return this.source_types = data;
      });
    }
  };
  return props;
};

controllers.DetailCtrl = function($scope, $rootScope, $http, $timeout, DetailFactory) {
  var load_location, reset, source_types;
  console.log("Detail Ctrl");
  reset = function() {
    $scope.location = null;
    $scope.current_location = null;
    $scope.current_review = null;
    return $scope.reviews = [];
  };
  reset();
  source_types = DetailFactory.get_source_types();
  load_location = function(id) {
    return $http.get(urls.location + id + ".json").success(function(data) {
      $scope.location = data;
      return console.log("DATA", data);
    });
  };
  $scope.location_access_types = ["Added by owner", "Permitted by owner", "Public", "Private but overhanging", "Private"];
  $scope.selected_review_source_type = function() {
    return "Source Type";
  };
  $scope.selected_review_access_type = function() {
    return "Access Type";
  };
  $scope.selected_location_source_type = function() {
    return "Source Type";
  };
  $rootScope.$on("SHOW-DETAIL", function(event, id) {
    console.log("SHOW-DETAIL", id);
    $scope.show_detail = true;
    if (id === void 0) {
      $scope.detail_context = "add_location";
      return $scope.menu_title = "Add";
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
  $scope.add_review = function(id) {
    if (id !== void 0) {
      $scope.current_review = _.findWhere($scope.reviews, {
        id: id
      });
      console.log("CR", $scope.current_review);
      $scope.menu_title = "Edit Review";
    } else {
      $scope.current_review = DetailFactory.get_new_review_model();
      $scope.menu_title = "Add Review";
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
