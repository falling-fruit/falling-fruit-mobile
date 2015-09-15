controllers.AuthCtrl = ($scope, $rootScope, $http, $timeout, $location, AuthFactory)->
  console.log "Auth Ctrl"

  $scope.authStateData = AuthFactory.data

  $scope.setAuthContext = (context)->
    console.log "Setting Auth Context To:", context
    AuthFactory.setAuthContext(context)

  $scope.login = ()->
    if $scope.SignInForm.$invalid
      alert "Please enter email and password and try again"
      return false

    $http.post(urls.login, user: $scope.login_user).then(
      (response)->
        if response.data isnt null and response.data.hasOwnProperty("auth_token")
          AuthFactory.save($scope.login_user.email, response.data.auth_token)
          $scope.login_user = AuthFactory.get_login_user_model()
          AuthFactory.hideAuth()
          $scope.SignInForm.$setUntouched()
          $rootScope.$broadcast "LOGGED-IN"
        else
          alert("Uh oh! We couldn't find your email or the password was incorrect. Please try again!")
          console.log "DATA isnt as expected", response.data
      , (response)->
        alert("There was an error. Please try again!")
        $scope.login_user.password = null
    )

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

  $scope.forgot_password = ()->
    console.log "FORGOT PASSWORD"
    user =
      email: $scope.forgot_password_user.email

    $http.post urls.forgot_password, user: user
    .success (data)->
      alert("Password reset sent! Check your email address, then come back and login.")
      AuthFactory.setAuthContext("login")
      $scope.forgot_password_user.email = null
      $scope.ForgotPassword.$setUntouched()
      #AuthFactory.forgot_password(email) What would this do?
    .error (data)->
      alert("We're sorry. There was an error. Please try again!")


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
