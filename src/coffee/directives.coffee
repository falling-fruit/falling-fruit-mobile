window.FFApp = {}

directives.mapContainer = ()->
  restrict: "C"
  template: ""
  scope:
    stoplist: "="
    directionstype: "="
  controller: ($scope, $element, $http, $rootScope, mapStateService)->
    container_elem = $element[0]
    window.FFApp.map_initialized = false
    window.FFApp.defaultZoom = 14
    window.FFApp.defaultMapTypeId = google.maps.MapTypeId.ROADMAP
    window.FFApp.defaultCenter = new google.maps.LatLng(40.015, -105.27)
    window.FFApp.markersArray = []
    window.FFApp.openMarker = null
    window.FFApp.openMarkerId = null
    window.FFApp.markersMax = 100
    window.FFApp.current_position = null
    window.FFApp.position_accuracy = null
    window.FFApp.position_marker = null
    window.FFApp.heading_marker = null
    window.FFApp.target_marker = null
    window.FFApp.muni = true
    window.FFApp.metric = true

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

    window.do_markers = (type_filter, cats) ->
      console.log "UPDATING MARKERS"
      mapStateService.setLoading("Loading...")
      bounds = window.FFApp.map_obj.getBounds()
      clear_offscreen_markers(bounds)
      return  if window.FFApp.markersArray.length >= window.FFApp.markersMax
      list_params =
        nelat: bounds.getNorthEast().lat()
        nelng: bounds.getNorthEast().lng()
        swlat: bounds.getSouthWest().lat()
        swlng: bounds.getSouthWest().lng()
        api_key: "***REMOVED***"

      if window.FFApp.muni
        list_params.muni = 1
      else
        list_params.muni = 0
      list_params.c = cats unless cats is `undefined`
      list_params.t = type_filter unless type_filter is `undefined`
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

    setup_marker = (marker,lid)->
      google.maps.event.addListener marker, "click", ()->
        window.FFApp.openMarkerId = lid
        window.FFApp.openMarker = marker
        $rootScope.$broadcast "SHOW-DETAIL", lid

    load_map = (center) ->
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

      google.maps.event.addListener window.FFApp.map_obj, "idle", ()->
        window.do_markers()

      # FIXME: Why use a marker instead of calling getCenter() when needed?
      window.FFApp.target_marker = new google.maps.Marker(
        position: window.FFApp.map_obj.getCenter()
        map: window.FFApp.map_obj
        clickable: false
        visible: false
      )
      window.FFApp.target_marker.bindTo('position', window.FFApp.map_obj, 'center')
      
      window.FFApp.map_initialized = true  
      $rootScope.$broadcast "MAP-LOADED"

    initialize = ()->
      return if window.FFApp.map_initialized == true

      mapStateService.setLoading("Loading...")

      if window.FFApp.map_elem isnt undefined
        container_elem.appendChild(window.FFApp.map_elem)
      else
        window.FFApp.map_elem = document.createElement("div")
        window.FFApp.map_elem.className = "map"
        container_elem.appendChild(window.FFApp.map_elem)

        navigator.geolocation.getCurrentPosition (position) ->
          lat = position.coords.latitude
          lng = position.coords.longitude
          center = new google.maps.LatLng(lat, lng)
          load_map(center)
        , ->
          #Error Handler Function (We can't get their location)
          load_map(window.FFApp.defaultCenter)

    console.log "LOADING MAP DIRECTIVE, STOPS NOT LOADED YET"
    initialize()

directives.ffLoadingMsg = (mapStateService)->
  restrict : "E"
  template: "<div class='loading' ng-class='{show: mapStateData.isLoading}'><div class='loading-message'>[{mapStateData.message || 'Loading...'}]</div></div>"
  replace: true
  link: ($scope, elem, attrs)->
    $scope.mapStateData = mapStateService.data

directives.confirmDialog = ()->
  restrict: "C"
  template: "<div class='conf-container'><div class='conf-txt'>[{confmsg}]</div><div class='conf-ok' ng-click='okfn()'>[{oktxt}]</div><div class='conf-cancel' ng-click='cancelfn()'>[{canceltxt}]</div></div>"
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
