function checkUsernameAndPassowrd(name, pass, container){
  var c = $(container);
  if (name.length < 3) {
    c.html('Username must be more than 3 characters');
  } else if (name.length > 16) {
    c.html('Username must be less than 16 characters');
  } else if (!/^[A-Za-z][\w\-]*$/.test(name)){
    c.html('Invalid username');
  } else if (pass.length < 6) {
    c.html('Password must be more than 6 characters');
  } else if (pass.length > 18){
    c.html('Password must be less than 18 characters');
  } else {
    c.empty();
    return true;
  }
  return false;
}
