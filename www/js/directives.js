window.FFApp = {};

directives.mapContainer = function() {
  return {
    restrict: "C",
    template: "",
    scope: {
      stoplist: "=",
      directionstype: "="
    },
    controller: function($scope, $element) {
      var add_markers_from_json, container_elem, do_markers, find_marker, initialize;
      container_elem = $element[0];
      window.FFApp.map_initialized = false;
      window.FFApp.markersArray = [];
      window.FFApp.openMarker = null;
      window.FFApp.openMarkerId = null;
      window.FFApp.markersMax = 5000;
      do_markers = function(muni, type_filter, cats) {
        var bounds, list_params;
        bounds = window.FFApp.map_obj.getBounds();
        if (window.FFApp.markersArray.length >= window.FFApp.markersMax) {
          return;
        }
        list_params = {
          nelat: bounds.getNorthEast().lat(),
          nelng: bounds.getNorthEast().lng(),
          swlat: bounds.getSouthWest().lat(),
          swlng: bounds.getSouthWest().lng(),
          api_key: "BJBNKMWM"
        };
        if (muni) {
          list_params.muni = 1;
        } else {
          list_params.muni = 0;
        }
        if (cats !== undefined) {
          list_params.c = cats;
        }
        if (type_filter !== undefined) {
          list_params.t = type_filter;
        }
        return $http.get(urls.markers, {
          params: list_params
        }).success(function(json) {
          return add_markers_from_json(json);
        });
      };
      find_marker = function(lid) {
        var i;
        i = 0;
        while (i < window.FFApp.markersArray.length) {
          if (window.FFApp.markersArray[i].id === lid) {
            return i;
          }
          i++;
        }
        return undefined;
      };
      add_markers_from_json = function(mdata, skip_ids) {
        var h, ho, i, len, lid, m, w, wo, _results;
        len = mdata.length;
        i = 0;
        _results = [];
        while (i < len) {
          lid = mdata[i]["location_id"];
          if ((skip_ids !== undefined) && (skip_ids.indexOf(parseInt(lid)) >= 0)) {
            continue;
          }
          if ((lid !== undefined) && (find_marker(lid) !== undefined)) {
            continue;
          }
          w = 36;
          h = 36;
          wo = parseInt(w / 2, 10);
          ho = parseInt(h / 2, 10);
          if (window.FFApp.openMarkerId === lid) {
            m = window.FFApp.openMarker;
          } else {
            m = new google.maps.Marker({
              icon: {
                url: "img/png/map-location-dot.png",
                size: new google.maps.Size(w, h),
                origin: new google.maps.Point(0, 0),
                anchor: new google.maps.Point(w * 0.4, h * 0.4)
              },
              position: new google.maps.LatLng(mdata[i]["lat"], mdata[i]["lng"]),
              map: window.FFApp.map_obj,
              title: mdata[i]["title"],
              draggable: false
            });
          }
          window.FFApp.markersArray.push({
            marker: m,
            id: mdata[i]["location_id"],
            type: "point",
            types: mdata[i]["types"],
            parent_types: mdata[i]["parent_types"]
          });
          _results.push(i++);
        }
        return _results;
      };
      initialize = function() {
        var chicago, map_options;
        if (window.FFApp.map_initialized === true) {
          return;
        }
        $scope.$emit("loading-start", "Loading maps...");
        if (window.FFApp.map_elem !== void 0) {
          container_elem.appendChild(window.FFApp.map_elem);
        } else {
          window.FFApp.map_elem = document.createElement("div");
          window.FFApp.map_elem.className = "map";
          container_elem.appendChild(window.FFApp.map_elem);
          chicago = new google.maps.LatLng(41.850033, -87.6500523);
          map_options = {
            center: chicago,
            zoom: 10,
            mapTypeId: google.maps.MapTypeId.ROADMAP
          };
          window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options);
          google.maps.event.addListenerOnce(window.FFApp.map_obj, "tilesloaded", function(event) {
            console.log("ADDING MARKERS");
            return do_markers(true);
          });
        }
        return window.FFApp.map_initialized = true;
      };
      console.log("LOADING MAP DIRECTIVE, STOPS NOT LOADED YET");
      return initialize();
    }
  };
};

directives.loadingIndicator = function() {
  return {
    restrict: "C",
    template: "<div class='loading-image'></div><div class='loading-text'></div>",
    controller: function($scope, $element) {
      var default_text, loadingElem, loadingImageElem, loadingTextElem, reset;
      console.log("Loading indicator init");
      default_text = "Please wait..";
      loadingElem = $element[0];
      loadingImageElem = loadingElem.getElementsByClassName('loading-image')[0];
      loadingTextElem = loadingElem.getElementsByClassName('loading-text')[0];
      reset = function(timeOut) {
        if (timeOut === null) {
          timeOut = 300;
        }
        return setTimeout(function() {
          loadingTextElem.innerHTML = "Please wait...";
          return loadingImageElem.className = "loading-image";
        }, timeOut);
      };
      loadingElem.onclick = function() {
        loadingElem.classList.remove("show");
        return reset();
      };
      $scope.$on("loading-start", function(event, message) {
        console.log("Loading start called");
        loadingTextElem.innerHTML = message !== null ? message : "Please wait..";
        return loadingElem.classList.add("show");
      });
      $scope.$on("loading-stop", function(event, message) {
        console.log("Loading stop called");
        loadingTextElem.innerHTML = message !== null ? message : "Done";
        loadingImageElem.classList.add("completed");
        return setTimeout(function() {
          loadingElem.classList.remove("show");
          return reset();
        }, 750);
      });
      $scope.$on("loading-stop-immly", function(event, message) {
        console.log("Loading stop immly called");
        loadingTextElem.innerHTML = message !== null ? message : "Done";
        loadingImageElem.classList.add("completed");
        loadingElem.classList.remove("show");
        return reset();
      });
      return $scope.$on("loading-error", function(event, message) {
        console.log("Loading Error called");
        loadingTextElem.innerHTML = message !== null ? message : "Please try again.";
        loadingElem.classList.add("show");
        loadingImageElem.classList.add("error");
        return setTimeout(function() {
          loadingElem.classList.remove("show");
          return reset();
        }, 1000);
      });
    }
  };
};

directives.confirmDialog = function() {
  return {
    restrict: "C",
    template: "<div class='conf-container'><div class='conf-txt'>[{confmsg}]</div><div class='conf-ok' ng-click='okfn()'>[{oktxt}]</div><div class='conf-cancel' ng-click='cancelfn()'>[{canceltxt}]</div></div>",
    scope: {
      confmsg: "@",
      okfn: "&",
      cancelfn: "&",
      oktxt: "@",
      canceltxt: "@"
    }
  };
};

directives.ngSwitcher = function() {
  var props;
  props = {
    restrict: "C",
    template: '<a ng-click="toggleSwitch()" class="switcher"><div class="switcher-circle"></div></a>',
    scope: {
      toggle: "="
    },
    controller: function($scope, $element) {
      var switcherElem;
      switcherElem = $element[0].getElementsByClassName("switcher")[0];
      if ($scope.toggle === true) {
        switcherElem.classList.add("on");
      }
      return $scope.toggleSwitch = function() {
        switcherElem.classList.toggle("on");
        return $scope.toggle = !$scope.toggle;
      };
    }
  };
  return props;
};
