function Bullet(canvas, options) {
  var __bullet = this;
  var canvas = canvas;

  var direction = options.direction;
  var velocity = options.velocity;
  var x = options.origin.x;
  var y = options.origin.y;
  var radius = 2;
  var color = 'red';
  var expired = false;
  var createTime = Date.now();

  var image = new fabric.Circle({
    radius: radius,
    fill: color,
    left: x - radius,
    top: y - radius,
    centeredRotation: true,
  });
  canvas.add(image);

  var bulletLongevity = 1000;
  var rate = 250;

  var velocity = {
    x: rate * Math.sin(direction * Math.PI / 180),
    y: rate * Math.cos(direction * Math.PI / 180),
  }

  this.tick = function(elapsed) { gameTick(elapsed); }
  this.expired = function() { return expired; }

  function gameTick(elapsed) {
    if(Date.now() - bulletLongevity > createTime) {
      expired = true;
      canvas.remove(image);
    }
    else {
      var posLeft = image.left + velocity.x * elapsed / 1000;
      var posTop = image.top - velocity.y * elapsed / 1000;
      image.set({left: posLeft, top: posTop})
    }
  }

}

function Ship(canvas) {
  var __ship = this;
  var canvas = canvas;
  var x = canvas.getWidth() / 2;
  var y = canvas.getHeight() / 2;
  var velocity = {magnitude: 0, direction: 0};

  // weapons
  var burstRate = 15;
  var firingRate = 5;
  var burstUnder = 5;
  var firing = false;
  var lastFired = 0;
  var bullets = [];

  // movement
  var turning = 0;
  var thrusting = false;
  var thrustAmount = 3;
  var rotationRate = 15;

  var image = new fabric.Polygon(
    [new fabric.Point(10, 0), new fabric.Point(20, 30), new fabric.Point(10, 25), new fabric.Point(0, 30)],
    {fill: 'black', left: x, top: y, angle: 0, centeredRotation: true,}
  );
  canvas.add(image);

  // ================================================
  // actions that may be invoked directly by the Game
  // ================================================
  this.keydown = function(action) { keydownAction(action) }
  this.keypress = function(action) { keypressAction(action) }
  this.keyup = function(action) { keyupAction(action) }
  this.tick = function(elapsed) { gameTick(elapsed) }


  // =====================================================
  // event handlers for which the UI may provide callbacks
  // =====================================================

  this.onMyEventHandler = null;


  // ===================================
  // private functions beyond this point
  // ===================================

  function keydownAction(action) {
    switch(action) {
      case 'fire':
        firing = true;
        break;
      case 'left':
        turning = -1;
        break;
      case 'right':
        turning = 1;
        break;
      case 'thrust':
        thrusting = true;
        break;
    }
  }

  function keypressAction(action) {
    switch(action) {
      case 'fire':
        break;
    }
  }

  function keyupAction(action) {
    switch(action) {
      case 'fire':
        firing = false;
        break;
      case 'left':
      case 'right':
        turning = 0;
        break;
      case 'thrust':
        thrusting = false;
        break;
    }
  }

  function gameTick(elapsed) {
    // is the user holding down the 'fire' button?
    if(firing) {
      tryToFire();
    }

    // update position and add 'drag'
    if(velocity.magnitude > 0) {
      // change position
      changePosition(elapsed);

      // add drag
      velocity.magnitude -= 1;
      if(velocity.magnitude < 0) { velocity.magnitude = 0; }
    }

    // is the user holding down either the left or the right button?
    if(turning != 0) {
      image.setAngle(image.angle + turning * rotationRate);
    }

    // add thrust component to the ship
    if(thrusting) {
      addThrust();
    }

    // eliminate bullets that are end-of-life
    var spliced = 0;
    for(var idx in bullets) {
      bullets[idx].tick(elapsed);
      if(bullets[idx].expired()) {
        bullets.splice(idx - spliced, 1);
        spliced += 1;
      }
    }
  }

  function changePosition(elapsed) {
    var posLeft = image.left + velocity.magnitude * Math.sin(velocity.direction) * elapsed / 1000;
    var posTop = image.top - velocity.magnitude * Math.cos(velocity.direction) * elapsed / 1000;
    image.set({left: posLeft, top: posTop})
  }

  // adds thrust to the ship
  function addThrust() {
    var addX = thrustAmount * Math.sin(image.angle * Math.PI / 180);
    var addY = thrustAmount * Math.cos(image.angle * Math.PI / 180);
    var xVel = velocity.magnitude * Math.sin(velocity.direction) + addX;
    var yVel = velocity.magnitude * Math.cos(velocity.direction) + addY;

    velocity.magnitude = Math.sqrt(Math.pow(xVel, 2) + Math.pow(yVel, 2));
    if(xVel >= 0 && yVel >= 0) {
      velocity.direction = (Math.PI / 2) - Math.atan2(yVel, xVel) + Math.PI;
    }
    console.log({
//      addX: addX, addY: addY,
//      xVel: xVel, yVel: yVel,
      velocityMag: velocity.magnitude,
      velocityDir: velocity.direction
    });
  }

  // returns the ship's firing point
  function fireOrigin() {
    var rad = image.getHeight() / 2;
    var center = image.getCenterPoint();
    return {
      x: center.x + rad * Math.sin(image.angle * Math.PI / 180),
      y: center.y - rad * Math.cos(image.angle * Math.PI / 180),
    }
  }

  // attemps to fire a bullet from this ship
  function tryToFire() {
    var rate = (bullets.length < burstUnder) ? burstRate : firingRate;
    if(Date.now() - (1000 / rate) > lastFired) {
      var bullet = new Bullet(canvas, {
        origin: fireOrigin(),
        direction: image.angle,
        velocity: 0,
      });
      bullets.push(bullet);
      lastFired = Date.now();
    }
  }
}
