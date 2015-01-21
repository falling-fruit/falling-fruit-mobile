var controllers, directives, factories, host, urls;

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
            auth_param = "user_email=" + (AuthFactory.get_email()) + "&auth_token=" + (AuthFactory.get_access_token()) + "&api_key=BJBNKMWM";
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
    client: "gme-fallingfruit"
    channel: "ff-mobile"
     *key: 'AIzaSyDm7gTRTOlOIsum_KOwfM-X13RYexMW41M'
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

host = "https://fallingfruit.org/";

urls = {
  login: host + "users/sign_in.json",
  register: host + "users.json",
  forgot_password: host + "users.json"
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
        return $scope.show_auth = false;
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

controllers.DetailCtrl = function($scope, $rootScope, $http, $location) {
  console.log("Detail Ctrl");
  $rootScope.$on("SHOW-DETAIL", function() {
    $scope.show_detail = true;
    $scope.detail_context = "add";
    return $scope.menu_title = "Add";
  });
  return $scope.menu_left_btn_click = function() {
    return $scope.show_detail = false;
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
    controller: function($scope, $element) {
      var clear_all_markers_and_directions, container_elem, initialize;
      container_elem = $element[0];
      window.FFApp.map_initialized = false;
      clear_all_markers_and_directions = function() {
        var i, marker, _i, _len, _ref, _results;
        if (FFApp.map_old_directions !== void 0) {
          FFApp.map_old_directions.setMap(null);
        }
        if (FFApp.dir_elem !== void 0) {
          window.FFApp.dir_elem.innerHTML = "";
        }
        if (FFApp.map_old_markers !== void 0) {
          _ref = FFApp.map_old_markers;
          _results = [];
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            marker = _ref[i];
            _results.push(marker.setMap(null));
          }
          return _results;
        }
      };
      initialize = function() {
        var chicago, map_options;
        if (window.FFApp.map_initialized === true) {
          return;
        }
        $scope.$emit("loading-start", "Loading maps...");
        if (window.FFApp.map_elem !== void 0) {
          container_elem.appendChild(window.FFApp.map_elem);
        } else {
          window.FFApp.map_elem = document.createElement("div");
          window.FFApp.map_elem.className = "map";
          container_elem.appendChild(window.FFApp.map_elem);
          chicago = new google.maps.LatLng(41.850033, -87.6500523);
          map_options = {
            center: chicago,
            zoom: 10,
            mapTypeId: google.maps.MapTypeId.ROADMAP
          };
          window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options);

          /*
          marker = new google.maps.Marker
            position: new google.maps.LatLng(43.069452, -89.411373),
            map: map
            title: "This is a marker!"
            animation: google.maps.Animation.DROP
           */
        }
        window.FFApp.map_initialized = true;
        return clear_all_markers_and_directions();
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

controllers.MenuCtrl = function($scope, $rootScope, $http, $location) {
  return console.log("Menu Ctrl");
};

controllers.SearchCtrl = function($scope, $rootScope, $http, $location) {
  console.log("Search Ctrl");
  $scope.current_view = "map";
  $scope.show_menu = false;
  $scope.map = {
    center: {
      latitude: 45,
      longitude: -73
    },
    zoom: 8
  };
  return $scope.show_detail = function() {
    return $rootScope.$broadcast("SHOW-DETAIL");
  };
};

FallingFruitApp.directive(directives);

FallingFruitApp.factory(factories);

FallingFruitApp.controller(controllers);
