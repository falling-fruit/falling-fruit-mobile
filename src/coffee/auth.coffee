factories.AuthFactory = ($rootScope)->
  props = 
    email: null
    access_token: null

    save: (email, access_token)->
      @email = email
      @access_token = access_token
      localStorage.setItem('EMAIL', email)
      localStorage.setItem('TOKEN', access_token)

    is_logged_in: ()->
      @email = localStorage.getItem("EMAIL") if not @email
      @access_token = localStorage.getItem("TOKEN") if not @access_token

      if not @email or not @access_token
        return false
      else 
        return true

    clear: ()->
      @email = @access_token =null
      localStorage.removeItem('EMAIL')
      localStorage.removeItem('TOKEN')

    get_access_token: ()->
      @access_token = localStorage.getItem("TOKEN") if not @access_token
      return @access_token

    get_email: ()->
      @email = localStorage.getItem("EMAIL") if not @email
      return @email

    get_login_user_model: ()->
      return email: @email, password: null

    needsAuth: (url)->
      return url.indexOf(".html") == -1 and url.indexOf("/users/") == -1


  return props

controllers.AuthCtrl = ($scope, $rootScope, $http, $location, AuthFactory)->
  console.log "Auth Ctrl"
  
  $rootScope.$on "LOGGED-OUT", ()->
    AuthFactory.clear()
    $scope.login_user = AuthFactory.get_login_user_model()
    $scope.show_auth = true
    $scope.auth_context = "login"

  $scope.login = ()->
    $http.post urls.login, $scope.login_user
    .success (data)->
      if data.hasOwnProperty("access_token") and data.access_token isnt null
        AuthFactory.save($scope.login_user.email, data.access_token)
      else
        console.log "DATA isnt as expected", data
    .error ()->
      $scope.login_user.password = null

  $scope.register = ()->

  $scope.forgot_password = ()->


  if not AuthFactory.is_logged_in()
    $rootScope.$broadcast "LOGGED-OUT" 
  else
    $rootScope.$broadcast "SHOW-MAP"