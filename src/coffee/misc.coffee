factories.MiscFactory = ($rootScope)->
  props =

    # Degrees to radians
    rad: (x)->
      return x * Math.PI / 180
  
    # Distance between points (meters)
    distance: (p1, p2)->
      R = 6378137;
      dlat = rad(p2.lat() - p1.lat())
      dlng = rad(p2.lng() - p1.lng())
      a = Math.sin(dlat / 2) * Math.sin(dlat / 2) +
        Math.cos(rad(p1.lat())) * Math.cos(rad(p2.lat())) *
        Math.sin(dlng / 2) * Math.sin(dlng / 2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      d = R * c
      return d

  return props
