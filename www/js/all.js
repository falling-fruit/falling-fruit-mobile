var FallingFruitApp, controllers, directives, factories, host, urls;

FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch', 'uiGmapgoogle-maps']);

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

FallingFruitApp.config(function(uiGmapGoogleMapApiProvider) {
  var params;
  params = {
    client: "***REMOVED***",
    channel: "ff-mobile",
    sensor: "false",
    v: '3.17',
    libraries: 'weather,geometry,visualization'
  };
  return uiGmapGoogleMapApiProvider.configure(params);
});

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

FallingFruitApp.controller(controllers);

FallingFruitApp.factory(factories);

FallingFruitApp.directive(directives);
