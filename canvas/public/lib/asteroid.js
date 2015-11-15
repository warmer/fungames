function Asteroid(canvas, options) {
  var __asteroid = this;
  var canvas = canvas;

  var direction = options.direction;
  var rate = options.velocity;
  var x = options.origin.x;
  var y = options.origin.y;
  var radius = options.radius;
  var color = options.color;
  var createTime = Date.now();

  var image = new fabric.Circle({
    radius: radius,
    fill: color,
    left: x - radius,
    top: y - radius,
    centeredRotation: true,
  });
  canvas.add(image);

  var velocity = {
    x: rate * Math.sin(to_rad(direction)),
    y: rate * Math.cos(to_rad(direction)),
  }

  this.tick = function(elapsed) { gameTick(elapsed); }
  this.image = function() { return image; }

  function gameTick(elapsed) {
    var posLeft = image.left + velocity.x * elapsed / 1000;
    var posTop = image.top - velocity.y * elapsed / 1000;
    if(posLeft > canvas.getWidth()) {
      posLeft = 0;
    }
    else if(posLeft < 0) {
      posLeft = canvas.getWidth();
    }
    if(posTop > canvas.getHeight()) {
      posTop = 0;
    }
    else if(posTop < 0) {
      posTop = canvas.getHeight();
    }

    image.set({left: posLeft, top: posTop});
    image.setCoords();
  }
}
