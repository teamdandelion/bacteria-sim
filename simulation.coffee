simulator_draw = (p) -> 
  i = 0
  env = new Environment(200, p)
  p.setup = () ->
    p.frameRate(10)
    p.size(1000, 500)
    p.background(0)

  # env = Environment(500, p)
  p.draw = () -> 
    if i < 6000
      i++
      p.background(0)
      env.step()
      console.log env.nBlobs

# e = new Environment(1000)
# for i in [0..1000]
#   e.step()

# wait for the DOM to be ready, 
# create a processing instance...
$(document).ready ->
  canvas = document.getElementById "processing"

  processing = new Processing(canvas, simulator_draw)