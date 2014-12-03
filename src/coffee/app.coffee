FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch'])

FallingFruitApp.config ($interpolateProvider)->
  $interpolateProvider.startSymbol('[{')
  $interpolateProvider.endSymbol('}]')

FallingFruitApp.config ['$httpProvider', ($httpProvider)->

  $httpProvider.interceptors.push ($q, $location, $rootScope, AuthFactory)->
    interceptor =
      request: (config)->
        if AuthFactory.needsAuth(config.url)
          auth_param = "user_email=#{AuthFactory.get_email()}&auth_token=#{AuthFactory.get_access_token()}&api_key=***REMOVED***"
          config.url += if config.url.indexOf("?") == -1 then "?#{auth_param}" else "&#{auth_param}"

        return config || $q.when(config)

      responseError: (rejection)->
        $rootScope.$broadcast "LOADING-STOP"
        if rejection.status == 401
          $rootScope.$broadcast "LOGGED-OUT"
        else
          $rootScope.$broadcast "LOADING-ERROR", "Please try again."

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

host = "http://fallingfruit.org/"

urls = 
  login: host + "users/sign_in.json"
  register: host + "users.json"
  forgot_password: host + "users.json"

controllers = {}
factories = {}
directives = {}
