factories.MiscFactory = function($rootScope) {
  var props;
  props = {
    rad: function(x) {
      return x * Math.PI / 180;
    },
    distance: function(p1, p2) {
      var R, a, c, d, dlat, dlng;
      R = 6378137;
      dlat = rad(p2.lat() - p1.lat());
      dlng = rad(p2.lng() - p1.lng());
      a = Math.sin(dlat / 2) * Math.sin(dlat / 2) + Math.cos(rad(p1.lat())) * Math.cos(rad(p2.lat())) * Math.sin(dlng / 2) * Math.sin(dlng / 2);
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      d = R * c;
      return d;
    }
  };
  return props;
};
