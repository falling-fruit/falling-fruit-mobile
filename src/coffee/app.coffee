window.FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch'])

FallingFruitApp.config ($interpolateProvider) ->
  $interpolateProvider.startSymbol('[{')
  $interpolateProvider.endSymbol('}]')

FallingFruitApp.config ($routeProvider)->
  $routeProvider
    #AUTH
    .when '/auth',
      templateUrl: 'html/auth.html'
      controller: 'AuthCtrl'

    .otherwise
      redirectTo: '/auth'