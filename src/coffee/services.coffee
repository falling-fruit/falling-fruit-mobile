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

  return props

factories.edibleTypesService = ($http)->
  props =
    data:
      edible_types: []
      edible_types_by_id: {}

  $http.get urls.source_types
    .success (data)->
      props.data.edible_types = data
      for row in data
        props.data.edible_types_by_id[row.id] = row

  return props

factories.AuthFactory = ($rootScope)->

  props =
    email: null
    access_token: null
    data:
      show_auth: true
      auth_context: "login"
      show_side_menu: false
      show_passwords: false

    save: (email, access_token)->
      @email = email
      @access_token = access_token
      localStorage.setItem('EMAIL', email)
      localStorage.setItem('TOKEN', access_token)

    is_logged_in: ()->
      @email = localStorage.getItem("EMAIL") if not @email
      @access_token = localStorage.getItem("TOKEN") if not @access_token

      if @email? and @access_token?
        @data.show_auth = false
        return true
      else
        return false

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
      return name: null, email: null, password: null, password_confirmation: null

    get_forgot_password_user_model: ()->
      return email: null

    needsAuth: (url)->
      return url.indexOf(".html") == -1 and url.indexOf("/users/") == -1

    hideAuth: ()->
      console.log "Hiding Auth View"
      @data.show_auth = false
      @data.show_passwords = false

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
      @data.show_passwords = false

    handleLoggedOut: ()->
      @.clear()
      @.showAuth()
      @.setAuthContext("login")
      @data.show_side_menu = false

    toggleSideMenu: ()->
      @data.show_side_menu = !@data.show_side_menu

    togglePasswordVisibility: ()->
      @data.show_passwords = !@data.show_passwords

  return props

factories.languageSwitcher = ($translate)->

  props =
    autonyms:
      "en": "English"
      "fr": "Français"
      "es": "Español"
    locale: $translate.use()

    setLocale: (locale)->
      $translate.use(locale)
      @locale = locale

    getLocale: ()->
      return @locale

    getAutonym: ()->
      return @autonyms[@locale]

  return props
