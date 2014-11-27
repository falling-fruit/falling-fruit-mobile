var FallingFruitApp, controllers, directives, factories;

FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch']);

FallingFruitApp.config(function($interpolateProvider) {
  $interpolateProvider.startSymbol('[{');
  return $interpolateProvider.endSymbol('}]');
});

FallingFruitApp.config([
  '$httpProvider', function($httpProvider) {
    return $httpProvider.interceptors.push(function($q, $location, $rootScope) {
      var interceptor;
      return interceptor = {
        request: function(config) {
          var auth_param;
          if (config.url.indexOf(".html") === -1) {
            if (!$rootScope.auth_token) {
              $rootScope.auth_token = localStorage.getItem("auth_token");
            }
            if (!$rootScope.auth_id) {
              $rootScope.auth_id = localStorage.getItem("auth_id");
            }
            auth_param = "auth_id=" + auth_id + "&auth_token=" + auth_token;
            config.url += config.url.indexOf("?") === -1 ? "?" + auth_param : "&" + auth_param;
          }
          return config || $q.when(config);
        },
        responseError: function(rejection) {
          $rootScope.$broadcast("LOADING-STOP");
          if (rejection.status === 401) {
            if ($rootScope.auth_token) {
              delete $rootScope.auth_token;
            }
            localStorage.removeItem("auth_token");
            if ($rootScope.auth_id) {
              delete $rootScope.auth_id;
            }
            localStorage.removeItem("auth_id");
            $rootScope.$broadcast("LOGGED-OUT");
          } else {
            $rootScope.$broadcast("loading-error", "Please try again.");
          }
          return rejection || $q.reject(rejection);
        }
      };
    });
  }
]);

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

controllers = {};

factories = {};

directives = {};

controllers.AuthCtrl = function($scope, $rootScope, $http, $location) {
  console.log("Auth Ctrl");
  $rootScope.$on("SHOW-AUTH", function() {
    $scope.show_auth = true;
    return $scope.auth_context = "login";
  });
  return $rootScope.$broadcast("SHOW-AUTH");
};

controllers.DetailCtrl = function($scope, $http, $location) {
  console.log("Detail Ctrl");
  return $scope.app_name = "Falling Fruit Detail";
};

controllers.MenuCtrl = function($scope, $rootScope, $http, $location) {
  return console.log("Menu Ctrl");
};

controllers.SearchCtrl = function($scope, $http, $location) {
  console.log("Search Ctrl");
  return $scope.app_name = "Falling Fruit";
};

FallingFruitApp.controller(controllers);

FallingFruitApp.factory(factories);

FallingFruitApp.directive(directives);
