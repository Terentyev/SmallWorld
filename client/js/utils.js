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

function checkAskNumber() {
  if (!isUInt($('#inputAskNum').attr('value'))) {
    $('#divAskNumError').html('You must enter integer').trigger('update');
    return true;
  }
  return false;
}

function checkEnough(cond, id) {
  if (cond) {
    $(id).html('Not enough tokens in hand').trigger('update');
    return true;
  }
  return false;
}
