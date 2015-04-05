window.FFApp = {}  

directives.mapContainer = ()->
  restrict: "C"
  template: ""
  scope:
    stoplist: "="
    directionstype: "="
  controller: ($scope, $element,$http,$rootScope)->
    container_elem = $element[0]
    window.FFApp.map_initialized = false
    window.FFApp.markersArray = []
    window.FFApp.openMarker = null
    window.FFApp.openMarkerId = null
    window.FFApp.markersMax = 100
    window.FFApp.defaultZoom = 14
    window.FFApp.current_position = null
    window.FFApp.position_marker = `undefined`
 
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
           
    do_markers = (muni, type_filter, cats) ->
      bounds = window.FFApp.map_obj.getBounds()
      clear_offscreen_markers(bounds)
      return  if window.FFApp.markersArray.length >= window.FFApp.markersMax
      list_params =
        nelat: bounds.getNorthEast().lat()
        nelng: bounds.getNorthEast().lng()
        swlat: bounds.getSouthWest().lat()
        swlng: bounds.getSouthWest().lng()
        api_key: "BJBNKMWM"

      if muni
        list_params.muni = 1
      else
        list_params.muni = 0
      list_params.c = cats  unless cats is `undefined`
      list_params.t = type_filter  unless type_filter is `undefined`
      $http.get(urls.markers,
        params: list_params
      ).success (json) ->
        add_markers_from_json json
    
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
        w = 36
        h = 36
        wo = parseInt(w / 2, 10)
        ho = parseInt(h / 2, 10)
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

            position: new google.maps.LatLng(mdata[i]["lat"], mdata[i]["lng"])
            map: window.FFApp.map_obj
            title: mdata[i]["title"]
            draggable: false
          )
          
          setup_marker m, lid
            
          window.FFApp.markersArray.push
            marker: m
            id: mdata[i]["location_id"]
            type: "point"
            types: mdata[i]["types"]
            parent_types: mdata[i]["parent_types"]

        i++

    setup_marker = (marker,lid)->
      google.maps.event.addListener marker, "click", ()->
        window.FFApp.openMarkerId = lid
        window.FFApp.openMarker = marker
        $rootScope.$broadcast "SHOW-DETAIL", lid

    initialize = ()->
      return if window.FFApp.map_initialized == true
      $scope.$emit("loading-start", "Loading maps...")
      if window.FFApp.map_elem isnt undefined
        container_elem.appendChild(window.FFApp.map_elem)
      else
        window.FFApp.map_elem = document.createElement("div")
        window.FFApp.map_elem.className = "map"
        container_elem.appendChild(window.FFApp.map_elem)
        # FIXME: currently map won't load if we cannot get a position
        navigator.geolocation.getCurrentPosition (position)->  
          map_options =
            center: new google.maps.LatLng(position.coords.latitude,position.coords.longitude) 
            zoom: window.FFApp.defaultZoom
            mapTypeId: google.maps.MapTypeId.ROADMAP
            
          window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options)
          window.FFApp.geocoder = new google.maps.Geocoder()
                            
          google.maps.event.addListener window.FFApp.map_obj, "idle", ()->
            console.log "UPDATING MARKERS"
            do_markers true
        
          window.FFApp.map_initialized = true
          $rootScope.$broadcast "MAP-LOADED"

    console.log "LOADING MAP DIRECTIVE, STOPS NOT LOADED YET"
    initialize()


directives.loadingIndicator = ()->
  restrict: "C"
  template: "<div class='loading-image'></div><div class='loading-text'></div>"
  controller: ($scope, $element)->
    console.log "Loading indicator init"
    default_text = "Please wait.."
    loadingElem = $element[0]
    loadingImageElem = loadingElem.getElementsByClassName('loading-image')[0]
    loadingTextElem = loadingElem.getElementsByClassName('loading-text')[0]

    reset = (timeOut)->
      timeOut = 300 if timeOut is null
      setTimeout ()->
        loadingTextElem.innerHTML = "Please wait..."
        loadingImageElem.className = "loading-image"
      , timeOut

    loadingElem.onclick = ()->
      loadingElem.classList.remove("show")
      reset()

    $scope.$on "loading-start", (event, message)->
      console.log "Loading start called"
      loadingTextElem.innerHTML = if message isnt null then message else "Please wait.."
      loadingElem.classList.add("show")


    $scope.$on "loading-stop", (event, message)->
      console.log "Loading stop called"
      loadingTextElem.innerHTML = if message isnt null then message else "Done"
      loadingImageElem.classList.add("completed")

      setTimeout ()->
        loadingElem.classList.remove("show")
        reset()
      , 750



    $scope.$on "loading-stop-immly", (event, message)->
      console.log "Loading stop immly called"
      loadingTextElem.innerHTML = if message isnt null then message else "Done"
      loadingImageElem.classList.add("completed")
      loadingElem.classList.remove("show")
      #loadingElem.classList.add("hidden")
      #setTimeout ()->
      #  loadingElem.classList.remove("hidden")
      #, 500
      reset()

    $scope.$on "loading-error", (event, message)->
      console.log "Loading Error called"
      loadingTextElem.innerHTML = if message isnt null then message else "Please try again."
      loadingElem.classList.add("show") #if not loadingElem.contains("show")
      loadingImageElem.classList.add("error")

      setTimeout ()->
        loadingElem.classList.remove("show")
        reset()
      , 1000

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
