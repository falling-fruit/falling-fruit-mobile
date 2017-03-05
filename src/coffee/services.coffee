# This service runs the loading animation and updates text
# services/factories
factories.mapStateService = ($translate)->

  props =
    data:
      isLoading: false
      message: ""

    setLoading: (msg)->
      $translate(msg).then((string)->
        props.data.message = string
        props.data.isLoading = true
      )

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

factories.locationsService = ($http) ->
  cachedData = null
  lastSearchParams = null

  props = {}

  props.fetchData = (options) ->
    console.log("locationsService.fetchData()")

    onSuccess = options.onSuccess ||
      throw new Error("locationsService.fetchData() requires an onSuccess handler")

    # bounds can be optionally passed in as a key
    bounds = options.bounds || window.FFApp.map_obj.getBounds()
    center = window.FFApp.map_obj.getCenter()

    params =
      lat: center.lat()
      lng: center.lng()
      nelat: bounds.getNorthEast().lat()
      nelng: bounds.getNorthEast().lng()
      swlat: bounds.getSouthWest().lat()
      swlng: bounds.getSouthWest().lng()

    if window.FFApp.muni
      params.muni = 1
    else
      params.muni = 0

    params.c = window.FFApp.cats unless window.FFApp.cats is null
    params.t = window.FFApp.selectedType.id unless window.FFApp.selectedType is null

    console.log("cachedData = ", cachedData)
    console.log("lastSearchParams = ", lastSearchParams)
    console.log("params = ", params)

    if cachedData && _.isEqual(lastSearchParams, params)
      console.log("--> hit the cache")
      return onSuccess(cachedData)

    lastSearchParams = params

    $http
      .get(urls.locations, params: params)
      .success (json) ->
        console.log("--> loaded from http")
        cachedData = json
        onSuccess(json)

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

factories.languageSwitcher = ($translate, amMoment)->

  props =
    autonyms:
      "en": "English"
      "fr": "Français"
      # "es": "Español"
    locale: $translate.use()

    applyLocale: ()->
      $translate.use(@locale)
      amMoment.changeLocale(@locale)

    getAutonym: ()->
      return @autonyms[@locale]

  return props
