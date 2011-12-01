function keys(arr) {
  var result = [];
  for (var i in arr) {
    if (arr.hasOwnProperty(i)) {
      result.push(i);
    }
  }
  return result;
}

function isUInt(i) {
  return !isNaN(i) && parseInt(i) == i && i >= 0;
}
