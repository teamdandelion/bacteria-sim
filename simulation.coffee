simulator_draw = (p) -> 
  i = 0
  env = new Environment(C.STARTING_BLOBS, p)
  running = on
  info = new InfoArea(p, env)
  p.mouseClicked = () -> 
    env.observeBlob(p.mouseX, p.mouseY)
    if !running
      p.background(0)
      env.drawAll()

  p.setup = () ->
    p.frameRate(10)
    p.size(C.X_BOUND, C.Y_BOUND + C.DISPLAY_BOUND)
    p.background(0)

  # env = Environment(500, p)
  p.draw = () -> 
    if running
      i++
      p.background(0)
      env.step()
    info.draw()

  p.keyPressed = () -> 
    console.log p.keyCode
    if p.keyCode == 32
      running = !running


# e = new Environment(1000)
# for i in [0..1000]
#   e.step()

# wait for the DOM to be ready, 
# create a processing instance...
$(document).ready ->
  canvas = document.getElementById "processing"

  processing = new Processing(canvas, simulator_draw)