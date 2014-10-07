FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch'])

FallingFruitApp.config ($interpolateProvider) ->
  $interpolateProvider.startSymbol('[{')
  $interpolateProvider.endSymbol('}]')

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
