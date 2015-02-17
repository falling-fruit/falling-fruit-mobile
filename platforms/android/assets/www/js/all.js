var auth_host, controllers, directives, factories, host, urls;

window.FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch']);

FallingFruitApp.config(function($interpolateProvider) {
  $interpolateProvider.startSymbol('[{');
  return $interpolateProvider.endSymbol('}]');
});

FallingFruitApp.config([
  '$httpProvider', function($httpProvider) {
    return $httpProvider.interceptors.push(function($q, $location, $rootScope, AuthFactory) {
      var interceptor;
      return interceptor = {
        request: function(config) {
          var auth_param;
          if (AuthFactory.needsAuth(config.url)) {
            auth_param = "user_email=" + (AuthFactory.get_email()) + "&auth_token=" + (AuthFactory.get_access_token()) + "&api_key=***REMOVED***";
            config.url += config.url.indexOf("?") === -1 ? "?" + auth_param : "&" + auth_param;
          }
          return config || $q.when(config);
        },
        responseError: function(rejection) {
          $rootScope.$broadcast("LOADING-STOP");
          if (rejection.status === 401) {
            $rootScope.$broadcast("LOGGED-OUT");
          } else {
            $rootScope.$broadcast("LOADING-ERROR", "Please try again.");
          }
          return rejection || $q.reject(rejection);
        }
      };
    });
  }
]);


/*
FallingFruitApp.config (uiGmapGoogleMapApiProvider)->
  params = 
    client: "***REMOVED***"
    channel: "ff-mobile"
     *key: '***REMOVED***'
    sensor: "false"
    v: '3.17'
    libraries: 'weather,geometry,visualization'
 
  uiGmapGoogleMapApiProvider.configure params
 */

FallingFruitApp.config(function($routeProvider) {
  return $routeProvider.when('/search', {
    templateUrl: 'html/search.html',
    controller: 'SearchCtrl'
  }).when('/detail', {
    templateUrl: 'html/detail.html',
    controller: 'DetailCtrl'
  }).otherwise({
    redirectTo: '/search'
  });
});

auth_host = "https://fallingfruit.org/";

host = auth_host + "api/";

urls = {
  login: auth_host + "users/sign_in.json",
  register: auth_host + "users.json",
  forgot_password: auth_host + "users.json",
  nearby: host + "locations/nearby.json",
  markers: host + "locations/markers.json",
  location: host + "locations/",
  add_location: host + "locations.json",
  source_types: host + "locations/types.json",
  reviews: function(id) {
    return host + ("locations/" + id + "/reviews.json");
  }
};

controllers = {};

factories = {};

directives = {};

factories.AuthFactory = function($rootScope) {
  var props;
  props = {
    email: null,
    access_token: null,
    save: function(email, access_token) {
      this.email = email;
      this.access_token = access_token;
      localStorage.setItem('EMAIL', email);
      return localStorage.setItem('TOKEN', access_token);
    },
    is_logged_in: function() {
      if (!this.email) {
        this.email = localStorage.getItem("EMAIL");
      }
      if (!this.access_token) {
        this.access_token = localStorage.getItem("TOKEN");
      }
      if (!this.email || !this.access_token) {
        return false;
      } else {
        return true;
      }
    },
    clear: function() {
      this.email = this.access_token = null;
      localStorage.removeItem('EMAIL');
      return localStorage.removeItem('TOKEN');
    },
    get_access_token: function() {
      if (!this.access_token) {
        this.access_token = localStorage.getItem("TOKEN");
      }
      return this.access_token;
    },
    get_email: function() {
      if (!this.email) {
        this.email = localStorage.getItem("EMAIL");
      }
      return this.email;
    },
    get_login_user_model: function() {
      return {
        email: this.email,
        password: null
      };
    },
    get_register_user_model: function() {
      return {
        name: null,
        email: null,
        password: null
      };
    },
    needsAuth: function(url) {
      return url.indexOf(".html") === -1 && url.indexOf("/users/") === -1;
    }
  };
  return props;
};

controllers.AuthCtrl = function($scope, $rootScope, $http, $location, AuthFactory) {
  console.log("Auth Ctrl");
  $rootScope.$on("LOGGED-OUT", function() {
    AuthFactory.clear();
    $scope.login_user = AuthFactory.get_login_user_model();
    $scope.register_user = AuthFactory.get_register_user_model();
    $scope.show_auth = true;
    return $scope.auth_context = "login";
  });
  $scope.login = function() {
    return $http.post(urls.login, {
      user: $scope.login_user
    }).success(function(data) {
      if (data.hasOwnProperty("auth_token") && data.auth_token !== null) {
        AuthFactory.save($scope.login_user.email, data.access_token);
        $scope.login_user = AuthFactory.get_login_user_model();
        $scope.show_auth = false;
        return $rootScope.$broadcast("LOGGED-IN");
      } else {
        return console.log("DATA isnt as expected", data);
      }
    }).error(function() {
      return $scope.login_user.password = null;
    });
  };
  $scope.register = function() {
    var user;
    user = {
      name: $scope.register_user.name,
      email: $scope.register_user.email,
      password: $scope.register_user.password
    };
    return $http.post(urls.register, {
      user: user
    }).success(function(data) {
      $scope.auth_context = "login";
      return $scope.login_user.email = $scope.register_user.email;
    }).error(function() {
      return $scope.register_user = AuthFactory.get_register_user_model();
    });
  };
  $scope.forgot_password = function() {};
  if (!AuthFactory.is_logged_in()) {
    return $rootScope.$broadcast("LOGGED-OUT");
  } else {
    return $rootScope.$broadcast("SHOW-MAP");
  }
};

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

window.FFApp = {};

directives.mapContainer = function() {
  return {
    restrict: "C",
    template: "",
    scope: {
      stoplist: "=",
      directionstype: "="
    },
    controller: function($scope, $element, $http, $rootScope) {
      var add_markers_from_json, clear_offscreen_markers, container_elem, do_markers, find_marker, initialize, setup_marker;
      container_elem = $element[0];
      window.FFApp.map_initialized = false;
      window.FFApp.markersArray = [];
      window.FFApp.openMarker = null;
      window.FFApp.openMarkerId = null;
      window.FFApp.markersMax = 100;
      window.FFApp.defaultZoom = 14;
      window.FFApp.current_position = null;
      window.FFApp.position_marker = undefined;
      clear_offscreen_markers = function() {
        var b, i, newMarkers, p;
        b = window.FFApp.map_obj.getBounds();
        i = 0;
        newMarkers = [];
        while (i < window.FFApp.markersArray.length) {
          p = window.FFApp.markersArray[i].marker.getPosition();
          if (!b.contains(p)) {
            window.FFApp.markersArray[i].marker.setMap(null);
          } else {
            newMarkers.push(window.FFApp.markersArray[i]);
          }
          i++;
        }
        return window.FFApp.markersArray = newMarkers;
      };
      do_markers = function(muni, type_filter, cats) {
        var bounds, list_params;
        bounds = window.FFApp.map_obj.getBounds();
        clear_offscreen_markers(bounds);
        if (window.FFApp.markersArray.length >= window.FFApp.markersMax) {
          return;
        }
        list_params = {
          nelat: bounds.getNorthEast().lat(),
          nelng: bounds.getNorthEast().lng(),
          swlat: bounds.getSouthWest().lat(),
          swlng: bounds.getSouthWest().lng(),
          api_key: "***REMOVED***"
        };
        if (muni) {
          list_params.muni = 1;
        } else {
          list_params.muni = 0;
        }
        if (cats !== undefined) {
          list_params.c = cats;
        }
        if (type_filter !== undefined) {
          list_params.t = type_filter;
        }
        return $http.get(urls.markers, {
          params: list_params
        }).success(function(json) {
          return add_markers_from_json(json);
        });
      };
      find_marker = function(lid) {
        var i;
        i = 0;
        while (i < window.FFApp.markersArray.length) {
          if (parseInt(window.FFApp.markersArray[i].id) === parseInt(lid)) {
            return i;
          }
          i++;
        }
        return undefined;
      };
      add_markers_from_json = function(mdata) {
        var h, ho, i, len, lid, m, n_found, n_limit, w, wo, _results;
        n_found = mdata.shift();
        n_limit = mdata.shift();
        len = mdata.length;
        i = 0;
        _results = [];
        while (i < len) {
          lid = mdata[i]["location_id"];
          if (find_marker(lid) !== undefined) {
            i++;
            continue;
          }
          if (window.FFApp.markersArray.length > window.FFApp.markersMax) {
            break;
          }
          w = 36;
          h = 36;
          wo = parseInt(w / 2, 10);
          ho = parseInt(h / 2, 10);
          if (window.FFApp.openMarkerId === lid) {
            m = window.FFApp.openMarker;
          } else {
            m = new google.maps.Marker({
              icon: {
                url: "img/png/map-location-dot.png",
                size: new google.maps.Size(w, h),
                origin: new google.maps.Point(0, 0),
                anchor: new google.maps.Point(w * 0.4, h * 0.4)
              },
              position: new google.maps.LatLng(mdata[i]["lat"], mdata[i]["lng"]),
              map: window.FFApp.map_obj,
              title: mdata[i]["title"],
              draggable: false
            });
            setup_marker(m, lid);
            window.FFApp.markersArray.push({
              marker: m,
              id: mdata[i]["location_id"],
              type: "point",
              types: mdata[i]["types"],
              parent_types: mdata[i]["parent_types"]
            });
          }
          _results.push(i++);
        }
        return _results;
      };
      setup_marker = function(marker, lid) {
        return google.maps.event.addListener(marker, "click", function() {
          window.FFApp.openMarkerId = lid;
          window.FFApp.openMarker = marker;
          return $rootScope.$broadcast("SHOW-DETAIL", lid);
        });
      };
      initialize = function() {
        if (window.FFApp.map_initialized === true) {
          return;
        }
        $scope.$emit("loading-start", "Loading maps...");
        if (window.FFApp.map_elem !== void 0) {
          return container_elem.appendChild(window.FFApp.map_elem);
        } else {
          window.FFApp.map_elem = document.createElement("div");
          window.FFApp.map_elem.className = "map";
          container_elem.appendChild(window.FFApp.map_elem);
          return navigator.geolocation.getCurrentPosition(function(position) {
            var map_options;
            map_options = {
              center: new google.maps.LatLng(position.coords.latitude, position.coords.longitude),
              zoom: window.FFApp.defaultZoom,
              mapTypeId: google.maps.MapTypeId.ROADMAP
            };
            window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options);
            google.maps.event.addListener(window.FFApp.map_obj, "idle", function() {
              console.log("UPDATING MARKERS");
              return do_markers(true);
            });
            return window.FFApp.map_initialized = true;
          });
        }
      };
      console.log("LOADING MAP DIRECTIVE, STOPS NOT LOADED YET");
      return initialize();
    }
  };
};

directives.loadingIndicator = function() {
  return {
    restrict: "C",
    template: "<div class='loading-image'></div><div class='loading-text'></div>",
    controller: function($scope, $element) {
      var default_text, loadingElem, loadingImageElem, loadingTextElem, reset;
      console.log("Loading indicator init");
      default_text = "Please wait..";
      loadingElem = $element[0];
      loadingImageElem = loadingElem.getElementsByClassName('loading-image')[0];
      loadingTextElem = loadingElem.getElementsByClassName('loading-text')[0];
      reset = function(timeOut) {
        if (timeOut === null) {
          timeOut = 300;
        }
        return setTimeout(function() {
          loadingTextElem.innerHTML = "Please wait...";
          return loadingImageElem.className = "loading-image";
        }, timeOut);
      };
      loadingElem.onclick = function() {
        loadingElem.classList.remove("show");
        return reset();
      };
      $scope.$on("loading-start", function(event, message) {
        console.log("Loading start called");
        loadingTextElem.innerHTML = message !== null ? message : "Please wait..";
        return loadingElem.classList.add("show");
      });
      $scope.$on("loading-stop", function(event, message) {
        console.log("Loading stop called");
        loadingTextElem.innerHTML = message !== null ? message : "Done";
        loadingImageElem.classList.add("completed");
        return setTimeout(function() {
          loadingElem.classList.remove("show");
          return reset();
        }, 750);
      });
      $scope.$on("loading-stop-immly", function(event, message) {
        console.log("Loading stop immly called");
        loadingTextElem.innerHTML = message !== null ? message : "Done";
        loadingImageElem.classList.add("completed");
        loadingElem.classList.remove("show");
        return reset();
      });
      return $scope.$on("loading-error", function(event, message) {
        console.log("Loading Error called");
        loadingTextElem.innerHTML = message !== null ? message : "Please try again.";
        loadingElem.classList.add("show");
        loadingImageElem.classList.add("error");
        return setTimeout(function() {
          loadingElem.classList.remove("show");
          return reset();
        }, 1000);
      });
    }
  };
};

directives.confirmDialog = function() {
  return {
    restrict: "C",
    template: "<div class='conf-container'><div class='conf-txt'>[{confmsg}]</div><div class='conf-ok' ng-click='okfn()'>[{oktxt}]</div><div class='conf-cancel' ng-click='cancelfn()'>[{canceltxt}]</div></div>",
    scope: {
      confmsg: "@",
      okfn: "&",
      cancelfn: "&",
      oktxt: "@",
      canceltxt: "@"
    }
  };
};

directives.ngSwitcher = function() {
  var props;
  props = {
    restrict: "C",
    template: '<a ng-click="toggleSwitch()" class="switcher"><div class="switcher-circle"></div></a>',
    scope: {
      toggle: "="
    },
    controller: function($scope, $element) {
      var switcherElem;
      switcherElem = $element[0].getElementsByClassName("switcher")[0];
      if ($scope.toggle === true) {
        switcherElem.classList.add("on");
      }
      return $scope.toggleSwitch = function() {
        switcherElem.classList.toggle("on");
        return $scope.toggle = !$scope.toggle;
      };
    }
  };
  return props;
};

controllers.MenuCtrl = function($scope, $rootScope, $http, $location) {
  return console.log("Menu Ctrl");
};

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
  $scope.update_position = function() {
    return navigator.geolocation.getCurrentPosition((function(position) {
      var h, w;
      console.log("position obtained!");
      window.FFApp.current_position = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      w = 69;
      h = 69;
      if (window.FFApp.position_marker === undefined) {
        return window.FFApp.position_marker = new google.maps.Marker({
          icon: {
            url: "img/png/control-me.png",
            size: new google.maps.Size(w, h),
            origin: new google.maps.Point(0, 0),
            anchor: new google.maps.Point(w * 0.4, h * 0.4)
          },
          position: window.FFApp.current_position,
          map: window.FFApp.map_obj,
          title: "Current Position",
          draggable: false
        });
      } else {
        window.FFApp.position_marker.setPosition(window.FFApp.current_position);
        window.FFApp.map_obj.panTo(window.FFApp.current_position);
        return window.FFApp.map_obj.setZoom(window.FFApp.defaultZoom);
      }
    }), function() {
      return console.log("Failed to get position");
    });
  };
  $scope.show_detail = function(location_id) {
    return $rootScope.$broadcast("SHOW-DETAIL", location_id);
  };
  return $scope.logout = function() {
    $rootScope.$broadcast("LOGGED-OUT");
    return $scope.show_menu = false;
  };
};

FallingFruitApp.directive(directives);

FallingFruitApp.factory(factories);

FallingFruitApp.controller(controllers);
