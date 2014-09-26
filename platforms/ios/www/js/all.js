var controllers;

window.FallingFruitApp = angular.module('FallingFruitApp', ['ngRoute', 'ngAnimate', 'ngTouch']);

FallingFruitApp.config(function($interpolateProvider) {
  $interpolateProvider.startSymbol('[{');
  return $interpolateProvider.endSymbol('}]');
});

FallingFruitApp.config(function($routeProvider) {
  return $routeProvider.when('/auth', {
    templateUrl: 'html/auth.html',
    controller: 'AuthCtrl'
  }).otherwise({
    redirectTo: '/auth'
  });
});

controllers = {};

controllers.AuthCtrl = function($scope, $http, $location) {
  console.log("Auth Ctrl");
  return $scope.app_name = "Falling Fruit";
};

FallingFruitApp.controller(controllers);
