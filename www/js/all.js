var FallingFruitApp, controllers, directives, factories;

FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch']);

FallingFruitApp.config(function($interpolateProvider) {
  $interpolateProvider.startSymbol('[{');
  return $interpolateProvider.endSymbol('}]');
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

controllers = {};

factories = {};

directives = {};

controllers.DetailCtrl = function($scope, $http, $location) {
  console.log("Detail Ctrl");
  return $scope.app_name = "Falling Fruit Detail";
};

controllers.MainCtrl = function($scope, $rootScope, $http, $location) {
  return console.log("Main Ctrl with Menu and Auth functionality");
};

controllers.SearchCtrl = function($scope, $http, $location) {
  console.log("Search Ctrl");
  return $scope.app_name = "Falling Fruit";
};

FallingFruitApp.controller(controllers);

FallingFruitApp.factory(factories);

FallingFruitApp.directive(directives);
