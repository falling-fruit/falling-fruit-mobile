factories.I18nFactory = ($rootScope)->
  props =

    distance_string: (meters)->
      if window.FFApp.metric
        if meters < 1000
          return parseFloat((meters).toPrecision(2)) + " m"
        else
          return parseFloat((meters / 1000).toPrecision(2)) + " km"
      else
        feet = Math.round(meters / 0.3048)
        if feet < 1000
          return parseFloat((feet).toPrecision(2)) + " ft"
        else
          return parseFloat((feet / 5280).toPrecision(2)) + " mi"

  return props
