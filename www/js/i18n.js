factories.I18nFactory = function($rootScope) {
  var props;
  props = {
    distance_string: function(meters) {
      var feet;
      if (window.FFApp.metric) {
        if (meters < 1000) {
          return parseFloat(meters.toPrecision(2)) + " m";
        } else {
          return parseFloat((meters / 1000).toPrecision(2)) + " km";
        }
      } else {
        feet = Math.round(meters / 0.3048);
        if (feet < 1000) {
          return parseFloat(feet.toPrecision(2)) + " ft";
        } else {
          return parseFloat((feet / 5280).toPrecision(2)) + " mi";
        }
      }
    },
    short_access_types: ["Added by owner", "Permitted by owner", "Public", "Private but overhanging", "Private"],
    ratings: ["Poor", "Fair", "Good", "Very good", "Excellent"],
    fruiting_status: ["Bare", "Flowering", "Fruiting", "Ripe"],
    months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
    season_string: function(season_start, season_stop, no_season) {
      if (no_season) {
        season_start = 0;
        season_stop = 11;
      }
      if (season_start !== null || season_stop !== null) {
        return (season_start !== null ? props.months[season_start] : "?") + " - " + (season_stop !== null ? props.months[season_stop] : "?");
      } else {
        return null;
      }
    }
  };
  return props;
};
