controllers.AuthCtrl = ($scope, $rootScope, $http, $location)->
  console.log "Auth Ctrl"
  
  $rootScope.$on "SHOW-AUTH", ()->
    $scope.show_auth = true
    $scope.auth_context = "login"

  $rootScope.$broadcast "SHOW-AUTH"