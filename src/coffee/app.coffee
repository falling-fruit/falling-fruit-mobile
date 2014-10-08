FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch'])

FallingFruitApp.config ($interpolateProvider)->
  $interpolateProvider.startSymbol('[{')
  $interpolateProvider.endSymbol('}]')

FallingFruitApp.config ['$httpProvider', ($httpProvider)->

  $httpProvider.interceptors.push ($q, $location, $rootScope)->
    interceptor =
      request: (config)->
        if config.url.indexOf(".html") == -1
          $rootScope.auth_token = localStorage.getItem("auth_token") if not $rootScope.auth_token
          $rootScope.auth_id = localStorage.getItem("auth_id") if not $rootScope.auth_id
          auth_param = "auth_id=#{auth_id}&auth_token=#{auth_token}"
          config.url += if config.url.indexOf("?") == -1 then "?#{auth_param}" else "&#{auth_param}"

        return config || $q.when(config)

      responseError: (rejection)->
        $rootScope.$broadcast "LOADING-STOP"
        if rejection.status == 401
          delete $rootScope.auth_token if $rootScope.auth_token
          localStorage.removeItem "auth_token"
          delete $rootScope.auth_id if $rootScope.auth_id
          localStorage.removeItem "auth_id"
          $rootScope.$broadcast "LOGGED-OUT"
        else
          $rootScope.$broadcast "loading-error", "Please try again."

        return rejection || $q.reject(rejection)

]

FallingFruitApp.config ($routeProvider)->
  $routeProvider
    .when '/search',
      templateUrl: 'html/search.html'
      controller: 'SearchCtrl'

    .when '/detail',
      templateUrl: 'html/detail.html'
      controller: 'DetailCtrl'

    .otherwise
      redirectTo: '/search'

controllers = {}
factories = {}
directives = {}
