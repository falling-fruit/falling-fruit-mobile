window.FFApp = {};

directives.mapContainer = function() {
  return {
    restrict: "C",
    template: "",
    scope: {
      stoplist: "=",
      directionstype: "="
    },
    controller: function($scope, $element, $http, $rootScope, mapStateService) {
      var add_markers_from_json, clear_offscreen_markers, container_elem, find_marker, initialize, load_map, setup_marker;
      container_elem = $element[0];
      window.FFApp.map_initialized = false;
      window.FFApp.defaultZoom = 14;
      window.FFApp.defaultMapTypeId = google.maps.MapTypeId.ROADMAP;
      window.FFApp.defaultCenter = new google.maps.LatLng(40.015, -105.27);
      window.FFApp.markersArray = [];
      window.FFApp.openMarker = null;
      window.FFApp.openMarkerId = null;
      window.FFApp.markersMax = 100;
      window.FFApp.current_position = null;
      window.FFApp.position_marker = undefined;
      window.FFApp.muni = true;
      window.FFApp.metric = true;
      clear_offscreen_markers = function() {
        var b, i, newMarkers, p;
        b = window.FFApp.map_obj.getBounds();
        i = 0;
        newMarkers = [];
        while (i < window.FFApp.markersArray.length) {
          p = window.FFApp.markersArray[i].marker.getPosition();
          if (!b.contains(p)) {
            window.FFApp.markersArray[i].marker.setMap(null);
          } else {
            newMarkers.push(window.FFApp.markersArray[i]);
          }
          i++;
        }
        return window.FFApp.markersArray = newMarkers;
      };
      window.clear_markers = function() {
        var marker, _i, _len, _ref;
        _ref = window.FFApp.markersArray;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          marker = _ref[_i];
          marker.marker.setMap(null);
        }
        return window.FFApp.markersArray = [];
      };
      window.do_markers = function(type_filter, cats) {
        var bounds, list_params;
        console.log("UPDATING MARKERS");
        mapStateService.setLoading("Loading Markers...");
        bounds = window.FFApp.map_obj.getBounds();
        clear_offscreen_markers(bounds);
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
        if (window.FFApp.muni) {
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
          add_markers_from_json(json);
          return mapStateService.removeLoading();
        });
      };
      find_marker = function(lid) {
        var i;
        i = 0;
        while (i < window.FFApp.markersArray.length) {
          if (parseInt(window.FFApp.markersArray[i].id) === parseInt(lid)) {
            return i;
          }
          i++;
        }
        return undefined;
      };
      add_markers_from_json = function(mdata) {
        var h, ho, i, len, lid, m, n_found, n_limit, w, wo, _results;
        n_found = mdata.shift();
        n_limit = mdata.shift();
        len = mdata.length;
        i = 0;
        _results = [];
        while (i < len) {
          lid = mdata[i]["location_id"];
          if (find_marker(lid) !== undefined) {
            i++;
            continue;
          }
          if (window.FFApp.markersArray.length > window.FFApp.markersMax) {
            break;
          }
          w = 25;
          h = 25;
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
              draggable: false,
              zIndex: 0
            });
            setup_marker(m, lid);
            window.FFApp.markersArray.push({
              marker: m,
              id: mdata[i]["location_id"],
              type: "point",
              types: mdata[i]["types"],
              parent_types: mdata[i]["parent_types"]
            });
          }
          _results.push(i++);
        }
        return _results;
      };
      setup_marker = function(marker, lid) {
        return google.maps.event.addListener(marker, "click", function() {
          window.FFApp.openMarkerId = lid;
          window.FFApp.openMarker = marker;
          return $rootScope.$broadcast("SHOW-DETAIL", lid);
        });
      };
      load_map = function(center) {
        var map_options;
        map_options = {
          center: center,
          zoom: window.FFApp.defaultZoom,
          mapTypeId: window.FFApp.defaultMapTypeId,
          mapTypeControl: false,
          streetViewControl: false,
          zoomControl: false,
          rotateControl: false,
          panControl: false
        };
        window.FFApp.map_obj = new google.maps.Map(window.FFApp.map_elem, map_options);
        window.FFApp.geocoder = new google.maps.Geocoder();
        google.maps.event.addListener(window.FFApp.map_obj, "idle", function() {
          return window.do_markers();
        });
        window.FFApp.map_initialized = true;
        return $rootScope.$broadcast("MAP-LOADED");
      };
      initialize = function() {
        if (window.FFApp.map_initialized === true) {
          return;
        }
        mapStateService.setLoading("Loading Map...");
        if (window.FFApp.map_elem !== void 0) {
          return container_elem.appendChild(window.FFApp.map_elem);
        } else {
          window.FFApp.map_elem = document.createElement("div");
          window.FFApp.map_elem.className = "map";
          container_elem.appendChild(window.FFApp.map_elem);
          return navigator.geolocation.getCurrentPosition(function(position) {
            var center, lat, lng;
            lat = position.coords.latitude;
            lng = position.coords.longitude;
            center = new google.maps.LatLng(lat, lng);
            return load_map(center);
          }, function() {
            return load_map(window.FFApp.defaultCenter);
          });
        }
      };
      console.log("LOADING MAP DIRECTIVE, STOPS NOT LOADED YET");
      return initialize();
    }
  };
};

directives.ffLoadingMsg = function(mapStateService) {
  return {
    restrict: "E",
    template: "<div class='loading' ng-class='{show: mapStateData.isLoading}'><div class='loading-message'>[{mapStateData.message || 'Loading...'}]</div></div>",
    replace: true,
    link: function($scope, elem, attrs) {
      return $scope.mapStateData = mapStateService.data;
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
