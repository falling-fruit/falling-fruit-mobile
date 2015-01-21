window.FFApp = {}

directives.mapContainer = ()->
  restrict: "C"
  template: ""
  scope:
    stoplist: "="
    directionstype: "="
  controller: ($scope, $element)->
    #console.log "Welcome to Google Maps directive"
    container_elem = $element[0]
    window.FFApp.map_initialized = false

    clear_all_markers_and_directions = ()->
      FFApp.map_old_directions.setMap(null) if FFApp.map_old_directions isnt undefined
      window.FFApp.dir_elem.innerHTML = "" if FFApp.dir_elem isnt undefined
      if FFApp.map_old_markers isnt undefined
        for marker, i in FFApp.map_old_markers
          marker.setMap(null)

    initialize = ()->
      return if window.FFApp.map_initialized == true
      $scope.$emit("loading-start", "Loading maps...")
      if window.FFApp.map_elem isnt undefined
        container_elem.appendChild(window.FFApp.map_elem)
        #dir_container_elem.appendChild(window.FFApp.dir_elem)
        #console.log "appendedchild"
      else
        window.FFApp.map_elem = document.createElement("div")
        window.FFApp.map_elem.className = "map"
        container_elem.appendChild(window.FFApp.map_elem)
        #container_elem.appendChild(switch_elem)

        #window.FFApp.dir_elem = document.createElement("div")
        #window.FFApp.dir_elem.className = "directions"
        #dir_container_elem.appendChild(window.FFApp.dir_elem)
        chicago = new google.maps.LatLng(41.850033, -87.6500523)

        map_options =
          center: chicago
          zoom: 10
          mapTypeId: google.maps.MapTypeId.ROADMAP

        window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options)

        ###
        marker = new google.maps.Marker
          position: new google.maps.LatLng(43.069452, -89.411373),
          map: map
          title: "This is a marker!"
          animation: google.maps.Animation.DROP
        ###
      window.FFApp.map_initialized = true

      clear_all_markers_and_directions()


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

