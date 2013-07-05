class Frontend
  constructor: (@p) -> 
    # assumption: The bounds of environment are 
    # greater than the display bounds, so when 
    # blobs wrap around we don't need to worry about
    # displaying them at both edges of the field 
    # at teh same time
    @running = on
    @sim = new Worker 'simulation.js'
    @renderer = new Renderer(@, @p)
    @sim.onmessage = (event) =>
      switch event.data.type
        when 'blobs'
          @renderer.receiveUpdate(event.data)
        when 'debug'
          console.log event.data.msg

    
    opt = {}
    opt['Kill all blobs'] = () => 
      @sim.postMessage 'killAllBlobs'
    opt['Add a blob'] = () =>
      @sim.postMessage 'addRandomBlob'

    
    gui = new dat.GUI()
    # # gui.onChange = () ->
    #   # console.log "CHANGE RECORDED"
    # gui.add(C, 'REPR_ENERGY_COST', 50, 5000)
    # gui.add(C, 'PHO_EPS', -1.0, 1.0)
    # gui.add(C, 'PHO_SQ_EPS', 0, .1)
    # gui.add(C, 'ATK_EPS', -1.0, 1.0)
    # gui.add(C, 'ATK_SQ_EPS', -.2, .2)
    # gui.add(C, 'BLOB_SIZE', 0.1, 5)
    # gui.add(C, 'MUTATION_CONSTANT', .01, 1)
    # gui.add(C, 'MUTATION_PROBABILITY', 0, .5)
    # gui.add(C, 'ENERGY_DECAY', 0, .1)
    # gui.add(C, 'AGE_ENERGY_DECAY', 0, .1)
    gui.add(opt, 'Kill all blobs')
    gui.add(opt, 'Add a blob')

    @running = on
    # if C.INFO_WINDOW then @infoArea = new InfoArea(@p, @env)

    @showNucleus = off
    @showShells = off
    @showReproduction = off

  step: () -> 
    if @running
      @renderer.step()

  requestUpdate: () -> 
    @sim.postMessage 'go'

  keyCode: (k) -> 
    if k == 32 # 'space'
      @running = !@running
    if k == 78 # 'n'
      @showNucleus = !@showNucleus
    if k == 83 # 's'
      @showShells = !@showShells
    if k == 82 # 'r'
      @showReproduction = !@showReproduction

  # mouseClick: (x, y) -> 
  #   if C.INFO_WINDOW
  #     @env.observeBlob(x+100,y+100)
  #     if !@running
  #       @drawAll()





      

simulator_draw = (p) -> 
  frontend = new Frontend(p)
  p.mouseClicked = () -> 
    frontend.mouseClick(p.mouseX, p.mouseY)
   
  p.setup = () ->
    p.frameRate(C.FRAME_RATE)
    p.size(C.DISPLAY_X, C.DISPLAY_Y + C.DISPLAY_BOUND)
    p.background(0,20,90)

  p.draw = () ->
    frontend.step()

  p.keyPressed = () -> 
    console.log p.keyCode
    frontend.keyCode(p.keyCode)

# wait for the DOM to be ready, 
# create a processing instance...
$(document).ready ->
  canvas = document.getElementById "processing"

  processing = new Processing(canvas, simulator_draw)