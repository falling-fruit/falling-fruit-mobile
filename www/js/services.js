factories.mapStateService = function() {
  var data, removeLoading, setLoading;
  data = {
    isLoading: false,
    message: ""
  };
  setLoading = function(msg) {
    data.isLoading = true;
    return data.message = msg;
  };
  removeLoading = function() {
    data.isLoading = false;
    return data.message = "";
  };
  return {
    data: data,
    setLoading: setLoading,
    removeLoading: removeLoading
  };
};
