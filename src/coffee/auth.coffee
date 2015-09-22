controllers.AuthCtrl = ($scope, $rootScope, $http, $timeout, $location, AuthFactory)->
  console.log "Auth Ctrl"

  $scope.authStateData = AuthFactory.data

  $scope.setAuthContext = (context)->
    console.log("Set AuthContext: ", context)
    AuthFactory.setAuthContext(context)

  $scope.login = ()->
    if $scope.SignInForm.$invalid
      alert("Please enter your email and password.")
      return false

    $http.post(urls.login, user: $scope.login_user).then(
      (response)->
        if response.data isnt null and response.data.hasOwnProperty("auth_token")
          AuthFactory.save($scope.login_user.email, response.data.auth_token)
          $scope.login_user = AuthFactory.get_login_user_model()
          AuthFactory.hideAuth()
          $scope.SignInForm.$setUntouched()
          $rootScope.$broadcast("LOGGED-IN")
        else
          alert("Oops! " + response.data.error)
          console.log("DATA isnt as expected", response.data)
      , (response)->
        alert("Oops! Either we couldn't find your email or the password was incorrect.")
        $scope.login_user.password = null
    )

  $scope.register = ()->
    if $scope.register_user
      user =
        name: $scope.register_user.name
        email: $scope.register_user.email
        password: $scope.register_user.password

    if $scope.RegisterForm.passwordConfirm.$error.match
      alert("Oops! Passwords do not match.")
      $scope.register_user.password = null
      $scope.register_user.password_confirmation = null
      return false
    
    $http.post(urls.register, user: user)
    .success (data)->
      #$rootScope.$broadcast("REGISTERED")
      alert("You've been registered! Check your email for a verification link, then come back and sign in.")
      AuthFactory.setAuthContext("login")
      $scope.login_user.email = $scope.register_user.email
    .error (data) ->
      console.log "Register DATA isnt as expected", data
      error_text = ""
      if data.errors.email
        error_text += "Email address " + data.errors.email  + ". "
        $scope.register_user.email = null
      if data.errors.password
        error_text += "Password " + data.errors.password + "."
        $scope.register_user.password = null
        $scope.register_user.password_confirmation = null
      alert("Oops! " + error_text)

  $scope.forgot_password = ()->
    console.log "FORGOT PASSWORD"
    user =
      email: $scope.forgot_password_user.email

    $http.post urls.forgot_password, user: user
    .success (data)->
      alert("Password reset sent! Check your email for further instructions, then come back and sign in.")
      AuthFactory.setAuthContext("login")
      $scope.forgot_password_user.email = null
      $scope.ForgotPassword.$setUntouched()
      #AuthFactory.forgot_password(email) What would this do?
    .error (data)->
      alert("Oops! Something went wrong. Please verify your email address and try again!")


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
