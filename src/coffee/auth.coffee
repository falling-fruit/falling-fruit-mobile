controllers.AuthCtrl = ($scope, $rootScope, $http, $timeout, $location, AuthFactory)->
  console.log "Auth Ctrl"

  $scope.authStateData = AuthFactory.data

  $scope.setAuthContext = (context)->
    console.log "Setting Auth Context To:", context
    AuthFactory.setAuthContext(context)

  $scope.login = ()->
    $http.post urls.login, user: $scope.login_user
    .success (data)->
      if data.hasOwnProperty("auth_token") and data.auth_token isnt null
        AuthFactory.save($scope.login_user.email, data.auth_token)
        $scope.login_user = AuthFactory.get_login_user_model()
        AuthFactory.hideAuth()
        $rootScope.$broadcast "LOGGED-IN"
      else
        alert("Uh oh! " + data.error + " Please try again!")
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
      #$rootScope.$broadcast("REGISTERED")
      alert("You've been registered! Please confirm your email address, then come back and login.")
      AuthFactory.setAuthContext("login")
      $scope.login_user.email = $scope.register_user.email
    .error (data) ->
      $scope.register_user = AuthFactory.get_register_user_model()
      console.log "Register DATA isnt as expected", data
      error_text = "Please check "
      error_text += "email as it is: " + data.errors.email if data.errors.email?
      error_text += " Password is " + data.errors.password if data.errors.password?
      alert("There was a registration error: " + error_text )

  # FIXME: Currently unused
  $scope.forgot_password = ()->
    console.log "FORGOT PASSWORD"
    email = $scope.forgot_password_user.email
    AuthFactory.forgot_password(email)

  $scope.$on "BACKBUTTON", ()->
    console.log "Caught BACKBUTTON event in controller"
    if $scope.authStateData.show_auth == true
      if $scope.authStateData.auth_context == 'login'
        navigator.app.exitApp();
      else
        AuthFactory.setAuthContext('login')
        # Wait until next digest loop, then update view
        $timeout(()->
          $scope.$apply()
        )
  
  # Shows map if already logged in
  if AuthFactory.is_logged_in()
    $rootScope.$broadcast "SHOW-MAP"
  else
    AuthFactory.handleLoggedOut()
