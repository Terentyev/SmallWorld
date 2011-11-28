var areaClickAction = areaDoNothing;


function areaClick(regionId) {
  areaClickAction();
}

/*******************************************************************************
   *         Area actions                                                      *
   ****************************************************************************/
function areaDoNothing() {
}

function areaConquer(regionId) {
  // TODO: do needed checks
  cmdConquer(regionId);
}

/*******************************************************************************
   *                                                                           *
   ****************************************************************************/
