#This service runs the loading animation and updates text
#services/factories
factories.mapStateService = ()->

  data =
    isLoading: false
    message: ""

  setLoading = (msg)->
    data.isLoading = true
    data.message = msg

  removeLoading = ()->
    data.isLoading = false
    data.message = ""

  return {
    data: data
    setLoading: setLoading
    removeLoading: removeLoading
  }
