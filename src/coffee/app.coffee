window.FallingFruitApp = angular.module('FallingFruitApp', [
  'ngRoute',
  'ngAnimate',
  'ngTouch',
  'pascalprecht.translate',
  'phrase',
  'uiSlider',
  'validation.match'
])

FallingFruitApp.value("phraseProjectId", "f198b01b5612afc8ac9f7d95b8ba1889")
FallingFruitApp.value("phraseEnabled", false)

FallingFruitApp.config(['$translateProvider', ($translateProvider)->
  $translateProvider.preferredLanguage('en')
  $translateProvider.useStaticFilesLoader
    prefix: '/locales/'
    suffix: '.json'
])

FallingFruitApp.config ($interpolateProvider)->
  $interpolateProvider.startSymbol('[{')
  $interpolateProvider.endSymbol('}]')

FallingFruitApp.config ['$httpProvider', ($httpProvider)->

  $httpProvider.interceptors.push ($q, $location, $rootScope, AuthFactory)->
    interceptor =
      request: (config)->
        if AuthFactory.needsAuth(config.url)
          auth_param = "user_email=#{AuthFactory.get_email()}&auth_token=#{AuthFactory.get_access_token()}&api_key=BJBNKMWM"
          config.url += if config.url.indexOf("?") == -1 then "?#{auth_param}" else "&#{auth_param}"

        return config || $q.when(config)

      responseError: (rejection)->
        $rootScope.$broadcast "LOADING-STOP"
        if rejection.status == 401
          AuthFactory.handleLoggedOut()
        else
          $rootScope.$broadcast "LOADING-ERROR", "Please try again."

        #return rejection || $q.reject(rejection)
        return $q.reject(rejection)
]

FallingFruitApp.constant("BASE_PATH", window.location.pathname)

FallingFruitApp.config ($routeProvider)->
  $routeProvider

    .when '/search',
      templateUrl: 'html/search.html'
      controller: 'SearchCtrl'

    .when '/detail',
      templateUrl: 'html/detail.html'
      controller: 'DetailCtrl'

    .when '/auth',
      templateUrl: 'html/auth.html'
      controller: 'AuthCtrl'

    .otherwise
      redirectTo: '/auth'

# catch cordova events and do things with them
FallingFruitApp.run ($rootScope, $window) ->
  console.log("Bootstrapped and Running Angular FallingFruitApp")
  onBack = (event)->
    console.log "Caught back button press"
    event.preventDefault();
    event.stopPropagation();
    console.log "Broadcasting backbutton press to application"
    $rootScope.$broadcast "BACKBUTTON"

  #document.addEventListener 'online', onOnline, false
  #document.addEventListener 'offline', onOffline, false
  document.addEventListener 'backbutton', onBack, false

  FastClick.attach(document.body)

  return

#This waits for the device to be ready before bootstrapping the angular app
#http://stackoverflow.com/questions/21556090/cordova-angularjs-device-ready
#MichaelOryl's Answer
angular.element(document).ready ()->
  if window.cordova
    console.log("Running in Cordova, will bootstrap AngularJS once 'deviceready' event fires.");
    document.addEventListener('deviceready', ()->
      console.log("Deviceready event has fired, bootstrapping AngularJS.");
      angular.bootstrap(document.body, ['FallingFruitApp']);
    , false);
  else
    console.log("Running in browser, bootstrapping AngularJS now.");
    angular.bootstrap(document.body, ['FallingFruitApp']);

  if navigator.userAgent.match(/iPhone/) || navigator.userAgent.match(/iPad/)
    document.body.classList.add("ios-device");

auth_host = "https://fallingfruit.org/"
#auth_host = "http://localhost:3000/"
host = auth_host + "api/"

urls =
  login: auth_host + "users/sign_in.json"
  register: auth_host + "users.json"
  forgot_password: auth_host + "users/password.json"

  nearby: host + "locations/nearby.json"
  markers: host + "locations/markers.json"

  location: host + "locations/"
  add_location: host + "locations.json"
  edit_location: (id) -> host + "locations/#{id}.json"

  source_types: host + "locations/types.json"

  reviews: (id)-> host + "locations/#{id}/reviews.json"
  add_review: (id) -> host + "locations/#{id}/add_review.json"

controllers = {}
factories = {}
directives = {}
