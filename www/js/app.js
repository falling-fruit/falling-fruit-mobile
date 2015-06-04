var auth_host, controllers, directives, factories, host, urls;

window.FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch', 'uiSlider']);

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

auth_host = "http://localhost:3000/";

host = auth_host + "api/";

urls = {
  login: auth_host + "users/sign_in.json",
  register: auth_host + "users.json",
  forgot_password: auth_host + "users.json",
  nearby: host + "locations/nearby.json",
  markers: host + "locations/markers.json",
  location: host + "locations/",
  add_location: host + "locations.json",
  edit_location: function(id) {
    return host + ("locations/" + id + ".json");
  },
  source_types: host + "locations/types.json",
  reviews: function(id) {
    return host + ("locations/" + id + "/reviews.json");
  },
  add_review: function(id) {
    return host + ("locations/" + id + "/add_review.json");
  }
};

controllers = {};

factories = {};

directives = {};
