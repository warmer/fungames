


function Game(canvas) {
  var __game = this;

  this.canvas = canvas;

  var keyMap = {
    left: 37,
    right: 39,
    thrust: 38,
    fire: 32,
  }
  var interval = null;
  var lastUpdate = 0;
  var ship = new Ship(canvas);

  // ==============================================
  // actions that may be invoked directly by the UI
  // ==============================================

  // handles incoming key presses
  this.keydown = function(e) { };
  this.keypress = function(e) { };
  this.keyup = function(e) { };

  this.run = function() {
    lastUpdate = Date.now();
    interval = setInterval(gameTick, 33);
    this.keydown = function(e) { keydownEvent(e) };
    this.keypress = function(e) { keypressEvent(e) };
    this.keyup = function(e) { keyupEvent(e) };
  }

  this.stop = function() { if(interval) { clearInterval(interval); interval = null; } }


  // =====================================================
  // event handlers for which the UI may provide callbacks
  // =====================================================

  this.onMyEventHandler = null;


  // ===================================
  // private functions beyond this point
  // ===================================

  function keydownEvent(e) {
    for(var key in keyMap) {
      if(e.keyCode == keyMap[key]) {
        ship.keydown(key);
      }
    }
  }

  function keypressEvent(e) {
    for(var key in keyMap) {
      if(e.keyCode == keyMap[key]) {
        ship.keypress(key);
      }
    }
  }

  function keyupEvent(e) {
    for(var key in keyMap) {
      if(e.keyCode == keyMap[key]) {
        ship.keyup(key);
      }
    }
  }

  function gameTick() {
    var updateTime = Date.now();
    ship.tick(updateTime - lastUpdate);
    lastUpdate = updateTime;

    canvas.renderAll();
  }
}
