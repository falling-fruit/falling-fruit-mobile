window.FFApp = {}

directives.mapContainer = ()->
  restrict: "C"
  template: ""
  scope:
    stoplist: "="
    directionstype: "="
  controller: ($scope, $element, $http, $rootScope, mapStateService, locationsService)->
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
      mapStateService.setLoading("status_message.loading_markers")

      bounds = window.FFApp.map_obj.getBounds()
      clear_offscreen_markers(bounds)
      return if window.FFApp.markersArray.length >= window.FFApp.markersMax

      locationsService
        .fetchData()
        .success (json) ->
          add_markers_from_json(json)
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
        lid = mdata[i]["id"]
        if find_marker(lid) isnt `undefined`
          i++
          continue
        if window.FFApp.selectedType
          if mdata[i]["type_ids"].indexOf(window.FFApp.selectedType.id) < 0
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
      lid = mdata["id"]
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
          draggable: false
          zIndex: 0
        )

        setup_marker m, lid

        window.FFApp.markersArray.push
          marker: m
          id: mdata["id"]
          type: "point"
          types: mdata["type_ids"]

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
        disableDefaultUI: true
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

      mapStateService.setLoading("status_message.loading_map")
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

directives.mapTypeSelect = (BASE_PATH, $timeout, $translate, edibleTypesService)->
  restrict: "E"
  templateUrl: "html/templates/map_type_select.html"
  scope:
    setTypeCallback: '&'
    api: '=?'

  controller: ($scope, $element, $attrs)->
    $scope.EdibleTypesData = edibleTypesService.data
    $scope.search_string = ""
    $scope.show_select = false
    $scope.show_reset_select = false
    $scope.selected_type_name = null

    $scope.typeFullName = (type) ->
      type.fullName($translate.use())

    $scope.closeKeyboard = ()->
      if window.cordova
        window.cordova.plugins.Keyboard.close()

    $scope.setType = (type)->
      $scope.setTypeCallback({type: type})
      if type == null
        $scope.selected_type_name = null
        $scope.show_reset_select = false
      else
        $scope.selected_type_name = type.name
        $scope.show_reset_select = true

    $scope.setVisible = (boolean)->
      $scope.show_select = boolean

    $scope.getShowResetSelect = ()->
      return $scope.show_reset_select

    $scope.getSelectedTypeName = ()->
      return $scope.selected_type_name

    $scope.api =
      getSelectedTypeName: $scope.getSelectedTypeName
      getShowResetSelect: $scope.getShowResetSelect
      setType: $scope.setType
      setVisible: $scope.setVisible

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
