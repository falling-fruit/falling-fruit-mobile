# This service runs the loading animation and updates text
# services/factories
factories.mapStateService = ()->

  props =
    data:
      isLoading: false
      message: ""

    setLoading: (msg)->
      @data.isLoading = true
      @data.message = msg

    removeLoading: ()->
      @data.isLoading = false
      @data.message = ""

  return props

factories.AuthFactory = ($rootScope)->

  props =
    email: null
    access_token: null
    data:
      show_auth: true
      auth_context: "login"
      show_side_menu: false

    save: (email, access_token)->
      @email = email
      @access_token = access_token
      localStorage.setItem('EMAIL', email)
      localStorage.setItem('TOKEN', access_token)

    forgot_password: (email)->
      console.log "Forgot Password:", email

    is_logged_in: ()->
      @email = localStorage.getItem("EMAIL") if not @email
      @access_token = localStorage.getItem("TOKEN") if not @access_token

      if not @email or not @access_token
        return false
      else
        return true

    clear: ()->
      console.log "Clearing Email / Token"
      @email = @access_token = null
      localStorage.removeItem('EMAIL')
      localStorage.removeItem('TOKEN')

    get_access_token: ()->
      @access_token = localStorage.getItem("TOKEN") if not @access_token
      return @access_token

    get_email: ()->
      @email = localStorage.getItem("EMAIL") if not @email
      return @email

    get_login_user_model: ()->
      console.log "Called get_login_user_model"
      return email: @email, password: null

    get_register_user_model: ()->
      console.log "Called get_register_user_model"
      return name: null, email: @email, password: null

    needsAuth: (url)->
      return url.indexOf(".html") == -1 and url.indexOf("/users/") == -1

    hideAuth: ()->
      console.log "Hiding Auth View"
      @data.show_auth = false

    showAuth: ()->
      console.log "Showing Auth View"
      @data.show_auth = true

    hideMenu: ()->
      console.log "HIDE SIDE MENU"
      @data.show_side_menu = false

    showMenu: ()->
      console.log "SHOW SIDE MENU"
      @data.show_side_menu = true

    setAuthContext: (context)->
      @data.auth_context = context

    handleLoggedOut: ()->
      @.clear()
      @.showAuth()
      @.setAuthContext("login")
      @data.show_side_menu = false

    toggleSideMenu: ()->
      @data.show_side_menu = !@data.show_side_menu

  return props
