factories.I18nFactory = ($rootScope)->
  props =

    distance_string: (meters)->
      if window.FFApp.metric
        meters = Math.round(meters)
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

    short_access_types: [
      "location.access.owner_added"
      "location.access.owner_permitted"
      "location.access.public"
      "location.access.private_overhanging"
      "location.access.private"
    ]

    ratings: [
      "review.rating.poor"
      "review.rating.fair"
      "review.rating.good"
      "review.rating.very_good"
      "review.rating.excellent"
    ]

    fruiting_status: [
      "review.fruiting.flowers"
      "review.fruiting.unripe_fruit"
      "review.fruiting.ripe_fruit"
    ]

  return props
