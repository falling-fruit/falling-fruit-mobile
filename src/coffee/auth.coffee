controllers.AuthCtrl = ($scope, $rootScope, $http, $location, AuthFactory)->
  console.log "Auth Ctrl"

  $rootScope.$on "LOGGED-OUT", ()->
    console.log "LOGGED-OUT ON", $scope.show_menu
    AuthFactory.clear()
    $scope.show_auth = true
    $scope.login_user = AuthFactory.get_login_user_model()
    $scope.register_user = AuthFactory.get_register_user_model()
    $scope.auth_context = "login"

  $scope.login = ()->
    $http.post urls.login, user: $scope.login_user
    .success (data)->
      if data.hasOwnProperty("auth_token") and data.auth_token isnt null
        AuthFactory.save($scope.login_user.email, data.auth_token)
        $scope.login_user = AuthFactory.get_login_user_model()
        $scope.show_auth = false
        $rootScope.$broadcast "LOGGED-IN"
      else
        console.log "DATA isnt as expected", data
    .error ()->
      $scope.login_user.password = null

  $scope.register = ()->
    user =
      name: $scope.register_user.name
      email: $scope.register_user.email
      password: $scope.register_user.password

    $http.post urls.register, user: user
    .success (data) ->
      $rootScope.$broadcast("REGISTERED")
      alert("You've been registered! Please confirm your email address, then come back and login.")
      $scope.auth_context = "login"
      $scope.login_user.email = $scope.register_user.email
    .error (data) ->
      $scope.register_user = AuthFactory.get_register_user_model()
      console.log "Register DATA isnt as expected", data
      error_text = "Please check "
      error_text += "email as it is: " + data.errors.email if data.errors.email?
      error_text += " Password is " + data.errors.password if data.errors.password?
      alert("There was a registration error: " + error_text )

  $scope.forgot_password = ()->
    console.log "FORGOT PASSWORD"
    #Does nothing?

  if not AuthFactory.is_logged_in()
    $rootScope.$broadcast "LOGGED-OUT"
  else
    $rootScope.$broadcast "SHOW-MAP"
