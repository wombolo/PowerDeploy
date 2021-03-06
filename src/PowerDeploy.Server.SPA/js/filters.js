var powerdeploy = angular.module('powerdeploy');

powerdeploy.filter('StripRavenDbIdPrefix', [
    function () {
      var result = function (id) {
        var index = id.indexOf('/') + 1;
        return id.substr(index, id.length - index);
      };

      return result;
    }
]);

powerdeploy.filter('boolConverter', [
    function () {
      var result = function (valueToCheck, trueValue, falseValue) {
        if (valueToCheck) {
          return trueValue;
        }

        return falseValue;
      };

      return result;
    }
]);

powerdeploy.filter('formatdate', [function () {
  var result = function (date, formatstring) {
    if (formatstring === null) {
      formatstring = 'DD.MMM.YYYY';
    }
    return moment(date).format(formatstring);
  };

  return result;
}]);

//powerdeploy.filter('convertdate', [function () {
//  var result = function (date) {
//    return moment(date).toDate();
//  };
//
//  return result;
//}]);