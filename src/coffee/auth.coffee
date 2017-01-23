controllers.AuthCtrl = ($scope, $rootScope, $http, $timeout, $location, AuthFactory, languageSwitcher, $translate)->
  console.log "Auth Ctrl"

  $scope.authStateData = AuthFactory.data

  $scope.setAuthContext = (context)->
    console.log("Set AuthContext: ", context)
    AuthFactory.setAuthContext(context)

  $scope.togglePasswordVisibility = ()->
    AuthFactory.togglePasswordVisibility()

  $scope.login = ()->
    if $scope.SignInForm.$invalid
      alert("Oops! Please enter your email and password.")
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
        alert("Oops! Please check your email and password and try again.")
        $scope.login_user.password = null
    )

  $scope.register = ()->
    if $scope.RegisterForm.$invalid
      alert("Oops! Please enter your email and password.")
      return false

    if $scope.register_user
      user =
        name: $scope.register_user.name
        email: $scope.register_user.email
        password: $scope.register_user.password

    $http.post(urls.register, user: user)
    .success (data)->
      alert("You've been registered! Check your email for a verification link, then come back and sign in.")
      AuthFactory.setAuthContext("login")
      initialize_sign_in($scope.register_user.email)
      $scope.register_user = AuthFactory.get_register_user_model()
      $scope.RegisterForm.$setUntouched()
    .error (data) ->
      console.log "Register DATA isn't as expected", data
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
    if $scope.ForgotPassword.$invalid
      alert("Oops! Please enter a valid email address.")
      return false

    if $scope.forgot_password_user
      user =
        email: $scope.forgot_password_user.email

    $http.post(urls.forgot_password, user: user)
    .success (data)->
      alert("Password reset sent! Check your email for further instructions, then come back and sign in.")
      AuthFactory.setAuthContext("login")
      initialize_sign_in($scope.forgot_password_user.email)
      $scope.forgot_password_user = AuthFactory.get_forgot_password_user_model()
      $scope.ForgotPassword.$setUntouched()
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

  # Initialize sign in form
  initialize_sign_in = (email)->
    $scope.login_user = {}
    if email
      $scope.login_user.email = email
    $scope.SignInForm.$setUntouched()

  # Shows map if already logged in
  if AuthFactory.is_logged_in()
    $rootScope.$broadcast "SHOW-MAP"
  else
    AuthFactory.handleLoggedOut()

  # Language switcher
  $scope.languageSwitcher = languageSwitcher
