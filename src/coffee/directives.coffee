window.FFApp = {}

directives.mapContainer = ()->
  restrict: "C"
  template: ""
  scope:
    stoplist: "="
    directionstype: "="
  controller: ($scope, $element, $http, $rootScope, mapStateService)->
    container_elem = $element[0]

    # Map settings
    window.FFApp.map_initialized = false
    window.FFApp.defaultZoom = 14
    window.FFApp.defaultMapTypeId = google.maps.MapTypeId.ROADMAP
    window.FFApp.defaultCenter = new google.maps.LatLng(40.015, -105.27)
    window.FFApp.map_idle = false

    # Locations
    window.FFApp.markersArray = []
    window.FFApp.openMarker = null
    window.FFApp.openMarkerId = null
    window.FFApp.markersMax = 100

    # Position & Heading
    window.FFApp.current_position = null
    window.FFApp.position_accuracy = null
    window.FFApp.current_heading = null

    # Filters
    window.FFApp.muni = true
    window.FFApp.metric = true
    window.FFApp.selectedType = null
    window.FFApp.cats = null
    window.FFApp.loadedTypes = []

    clear_offscreen_markers = () ->
      b = window.FFApp.map_obj.getBounds()
      i = 0
      newMarkers = []
      while i < window.FFApp.markersArray.length
        p = window.FFApp.markersArray[i].marker.getPosition()
        if !b.contains(p)
          window.FFApp.markersArray[i].marker.setMap(null)
        else
          newMarkers.push(window.FFApp.markersArray[i])
        i++
      window.FFApp.markersArray = newMarkers

    window.clear_markers = () ->
      for marker in window.FFApp.markersArray
        marker.marker.setMap(null)
      window.FFApp.markersArray = []

    window.do_markers = () ->
      console.log "UPDATING MARKERS"
      mapStateService.setLoading("Loading markers")

      bounds = window.FFApp.map_obj.getBounds()
      clear_offscreen_markers(bounds)
      return  if window.FFApp.markersArray.length >= window.FFApp.markersMax
      list_params =
        nelat: bounds.getNorthEast().lat()
        nelng: bounds.getNorthEast().lng()
        swlat: bounds.getSouthWest().lat()
        swlng: bounds.getSouthWest().lng()
      if window.FFApp.muni
        list_params.muni = 1
      else
        list_params.muni = 0
      list_params.c = window.FFApp.cats unless window.FFApp.cats is null
      list_params.t = window.FFApp.selectedType.id unless window.FFApp.selectedType is null
      $http.get(urls.markers,
        params: list_params
      ).success (json) ->
        add_markers_from_json json
        mapStateService.removeLoading()

    find_marker = (lid) ->
      i = 0
      while i < window.FFApp.markersArray.length
        return i if parseInt(window.FFApp.markersArray[i].id) is parseInt(lid)
        i++
      `undefined`

    add_markers_from_json = (mdata) ->
      n_found = mdata.shift()
      n_limit = mdata.shift()
      len = mdata.length
      i = 0
      while i < len
        lid = mdata[i]["location_id"]
        if find_marker(lid) isnt `undefined`
          i++
          continue
        if window.FFApp.selectedType
          if mdata[i]["types"].concat(mdata[i]["parent_types"]).indexOf(window.FFApp.selectedType.id) < 0
            i++
            continue
        if window.FFApp.markersArray.length > window.FFApp.markersMax
          break
        window.add_marker(mdata[i])
        i++

    window.add_marker = (mdata)->
      w = 25
      h = 25
      wo = parseInt(w / 2, 10)
      ho = parseInt(h / 2, 10)
      lid = mdata["location_id"]
      if window.FFApp.openMarkerId is lid
        m = window.FFApp.openMarker
      else
        m = new google.maps.Marker(
          icon:
            url: "img/png/map-location-dot.png"
            size: new google.maps.Size(w, h)
            origin: new google.maps.Point(0, 0)

            # by convention, icon center is at ~40%
            anchor: new google.maps.Point(w * 0.4, h * 0.4)

          position: new google.maps.LatLng(mdata["lat"], mdata["lng"])
          map: window.FFApp.map_obj
          title: mdata["title"]
          draggable: false
          zIndex: 0
        )

        setup_marker m, lid

        window.FFApp.markersArray.push
          marker: m
          id: mdata["location_id"]
          type: "point"
          types: mdata["types"]
          parent_types: mdata["parent_types"]

    setup_marker = (marker,location_id)->
      google.maps.event.addListener marker, "click", ()->
        window.FFApp.openMarkerId = location_id
        window.FFApp.openMarker = marker
        $rootScope.$broadcast "SHOW-LOCATION", location_id

    load_map = (center)->
      map_options =
        center: center
        zoom: window.FFApp.defaultZoom
        mapTypeId: window.FFApp.defaultMapTypeId
        mapTypeControl: false
        streetViewControl: false
        zoomControl: false
        rotateControl: false
        panControl: false
        tilt: 0

      window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options)
      window.FFApp.geocoder = new google.maps.Geocoder()

      window.FFApp.position_marker = new google.maps.Marker(
        icon:
          path: google.maps.SymbolPath.CIRCLE
          fillColor: '#1C95F2'
          fillOpacity: 1
          strokeColor: '#FFFFFF'
          strokeOpacity: 1
          strokeWeight: 1
          scale: 9
        position: center
        map: window.FFApp.map_obj
        draggable: false
        clickable: false
        zIndex: 100
        visible: false
      )

      window.FFApp.accuracy_marker = new google.maps.Circle(
        center: center
        radius: 10
        map: window.FFApp.map_obj
        fillColor: '#1C95F2'
        fillOpacity: 0.05
        strokeColor: '#1C95F2'
        strokeOpacity: 0.25
        strokeWeight: 1
        clickable: false
        zIndex: 99
        visible: false
      )
      window.FFApp.accuracy_marker.bindTo('center', window.FFApp.position_marker, 'position')
      window.FFApp.accuracy_marker.bindTo('visible', window.FFApp.position_marker, 'visible')

      window.FFApp.heading_marker = new google.maps.Marker(
        icon:
          path: "M10,6.9L5,0L0,6.9C1.4,6,3.1,5.5,4.9,5.5C6.7,5.5,10,6.9,10,6.9z"
          fillColor: '#1C95F2'
          fillOpacity: 1
          strokeWeight: 0
          scale: 1.3
          rotation: 0
          anchor: new google.maps.Point(5, 15)
        position: center
        map: window.FFApp.map_obj
        draggable: false
        clickable: false
        zIndex: 100
        visible: false
      )
      window.FFApp.heading_marker.bindTo('position', window.FFApp.position_marker, 'position')

      # When the map stops being scrolled by the user this fires
      window.FFApp.map_obj.addListener("idle", ()->
        window.FFApp.map_idle = true
        window.do_markers()
      )
      window.FFApp.map_obj.addListener("dragstart", ()->
        window.FFApp.map_idle = false
      )

      window.FFApp.map_initialized = true
      $rootScope.$broadcast "MAP-LOADED"

    initialize = ()->
      return if window.FFApp.map_initialized == true

      mapStateService.setLoading("Loading map")
      window.FFApp.map_elem = document.getElementById("map")

      if navigator.geolocation
        navigator.geolocation.getCurrentPosition( (position)->
          lat = position.coords.latitude
          lng = position.coords.longitude
          center = new google.maps.LatLng(lat, lng)
          load_map(center)
        , (err)->
          #Error Handler Function (We can't get their location)
          load_map(window.FFApp.defaultCenter)
        , {maximumAge: 3000, timeout: 4000, enableHighAccuracy: true}
        )
      else
        load_map(window.FFApp.defaultCenter)


    console.log "LOADING MAP DIRECTIVE, STOPS NOT LOADED YET"
    #deviceready should be used here, but doesn't seem to work well with how app is architected.
    initialize()

directives.ffLoadingMsg = (mapStateService)->
  restrict : "E"
  template: "<div class='loading-container'><div class='loading' ng-class='{show: mapStateData.isLoading}'><div class='loading-message'>{{mapStateData.message}}</div></div></div>"
  replace: true
  link: ($scope, elem, attrs)->
    $scope.mapStateData = mapStateService.data

directives.confirmDialog = ()->
  restrict: "C"
  template: "<div class='conf-container'><div class='conf-txt'>{{confmsg}}</div><div class='conf-ok' ng-click='okfn()'>{{oktxt}}</div><div class='conf-cancel' ng-click='cancelfn()'>{{canceltxt}}</div></div>"
  scope:
    confmsg: "@"
    okfn: "&"
    cancelfn: "&"
    oktxt: "@"
    canceltxt: "@"

directives.ngSwitcher = ()->
  props =
    restrict: "C"
    template: '<a ng-click="toggleSwitch()" class="switcher"><div class="switcher-circle"></div></a>'
    scope:
      toggle: "="
    controller: ($scope, $element)->
      switcherElem = $element[0].getElementsByClassName("switcher")[0]
      switcherElem.classList.add("on") if $scope.toggle == true

      $scope.toggleSwitch = ()->
        switcherElem.classList.toggle("on")
        $scope.toggle = !$scope.toggle

  return props

directives.mapTypeSelect = (BASE_PATH, $timeout, $translate, edibleTypesService)->
  restrict: "E"
  templateUrl: "html/templates/map_type_select.html"

  link: ($scope, $element, $attrs)->
    $translate("glossary.type.one").then((translation)->
      $scope.select_placeholder = translation
    )
    $scope.edible_types_data = edibleTypesService.data
    $scope.show_reset_select = false
    $scope.show_reset = false
    $scope.search_string = ""
    $scope.type_ids = []

    $scope.closeKeyboard = ()->
      if window.cordova
        window.cordova.plugins.Keyboard.close()

    $scope.checkSearchLength = ()->
      if $scope.search_string.length == 0
        $scope.show_reset = false
      else
        $scope.show_reset = true

    $scope.updateSelectedEdibleType = (type)->
      $scope.type_ids.push(type.id) if $scope.type_ids.indexOf(type.id) == -1
      window.FFApp.selectedType = type
      window.clear_markers()
      window.do_markers()
      $scope.reset_list()
      $scope.show_select = false
      $scope.show_reset_select = true
      $scope.select_placeholder = type.name

    $scope.resetSearch = ()->
      $scope.search_string = ""
      $scope.show_reset = false

    $scope.resetSelect = ()->
      $scope.type_ids = []
      $scope.show_reset_select = false
      $translate("glossary.type.one").then((translation)->
        $scope.select_placeholder = translation
      )
      window.FFApp.selectedType = null
      window.clear_markers()
      window.do_markers()
      $scope.reset_list()

    $scope.removeEdibleType = (id)->
      _.remove($scope.type_ids, (arr_id) ->
          return arr_id == id
      )
      window.FFApp.selectedType = null
      window.clear_markers()
      window.do_markers()
      $scope.reset_list()

    $scope.cancel = ()->
      $scope.show_select = false

directives.locationTypeSelect = (BASE_PATH, $timeout, $translate, edibleTypesService)->
  restrict: "E"
  templateUrl: "html/templates/location_type_select.html"
  scope:
    location: "="

  link: ($scope, $element, $attrs) ->
    $scope.edible_types_data = edibleTypesService.data
    $scope.show_types = false
    $scope.filters = {}
    $scope.filtered = false
    $scope.et_quantity = 0
    $scope.filters.edible_types = null

    $scope.blurInput = ()->
      #wait for all other handlers to run first
      #like the click handler then blur
      $timeout(()->
        $scope.show_types = false
      , 150)

    $scope.checkInputTypedLength = ()->
      max_results = $scope.edible_types_data.edible_types.length
      if $scope.filters.edible_types.length < 2
        $scope.et_quantity = 0
        $scope.filtered = false
      else
        $scope.et_quantity = max_results
        $scope.filtered = true

    $scope.updateSelectedEdibleType = (type)->
      $scope.location.type_ids = [] if $scope.location.type_ids is undefined
      $scope.location.type_ids.push(type.id) if $scope.location.type_ids.indexOf(type.id) == -1
      $scope.filters.edible_types = null
      $scope.show_types = false
      $scope.et_quantity = 0
      $scope.filtered = false

    $scope.removeEdibleType = (id)->
      #index = $scope.location.type_ids.indexOf(type.name)
      #$scope.location.type_ids.splice(index, 1)
      _.remove($scope.location.type_ids, (arr_id) ->
          return arr_id == id
      )

# Do something extra on touchstart and/or click event
#http://stackoverflow.com/a/24745264
directives.ngTouchClick = ()->
  link: ($scope, $element, $attrs)->
    $element.bind 'touchstart click', (e)->
      $scope.$apply $attrs['ngTouchClick']
      return
    return

directives.quietClick = ()->
  link: ($scope, $element, $attrs)->
    $element.bind 'touchstart click', (e)->
      e.preventDefault()
      e.stopPropagation()
      return
    return
