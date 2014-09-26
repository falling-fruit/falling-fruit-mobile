controllers = {}

controllers.AuthCtrl = ($scope, $http, $location)->
  console.log "Auth Ctrl"
  $scope.app_name = "Falling Fruit"

FallingFruitApp.controller controllers
