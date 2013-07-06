class Frontend
  constructor: (@p) -> 
    # assumption: The bounds of environment are 
    # greater than the display bounds, so when 
    # blobs wrap around we don't need to worry about
    # displaying them at both edges of the field 
    # at teh same time
    @running = on
    @sim = new Worker 'simulation.js'
    @sim.onmessage = (event) =>
      switch event.data.type
        when 'blobs'
          @renderer.receiveUpdate(event.data)
        when 'debug'
          console.log event.data.msg
    @updateConstants() # This initializes the simulation with the constants we are using
    # It's required for the sim to start operating
    @setupGui()
    @addBlobs(4)
    @renderer = new Renderer(@, @p)
    @running = on
    $(window).resize(
      () => 
        C.X_BOUND = $(window).width()
        C.Y_BOUND = $(window).height()
        @p.size(C.X_BOUND, C.Y_BOUND)
        @updateConstants()
    )

  updateConstants: () -> 
    newC = {}
    for k,v of C
      newC[k] = v
    @sim.postMessage {type: 'updateConstants', data: newC}

  setupGui: () ->
    opt = {}
    opt['Kill all blobs'] = () => 
      @sim.postMessage {type: 'killAllBlobs'}
    opt['Add a blob'] = () =>
      @sim.postMessage {type: 'addRandomBlob'}

    
    gui = new dat.GUI()

    addSlider = (name, min, max, step) => 
      step ?= (max-min)/100
      gui.add(C, name, min, max, step).onFinishChange(
        (newVal) => @updateConstants()
        )
    addSlider('REPR_ENERGY_COST', 100, 2000)
    addSlider('PHO_EPS', -1.0, 1.0)
    addSlider('PHO_SQ_EPS', 0, .1)
    addSlider('ATK_EPS', -1.0, 1.0)
    addSlider('ATK_SQ_EPS', -.2, .2)
    addSlider('BLOB_SIZE', 0.1, 5)
    addSlider('MUTATION_CONSTANT', .01, 1)
    addSlider('MUTATION_PROBABILITY', 0, .5)
    addSlider('ENERGY_DECAY', 0, .1)
    addSlider('AGE_ENERGY_DECAY', 0, .1)
    gui.add(opt, 'Kill all blobs')
    gui.add(opt, 'Add a blob')

    # if C.INFO_WINDOW then @infoArea = new InfoArea(@p, @env)

    @showNucleus = off
    @showShells = off
    @showReproduction = off

  step: () -> 
    if @running
      @renderer.step()

  requestUpdate: () -> 
    @sim.postMessage {type: 'go'}

  addBlobs: (n) -> 
    @sim.postMessage {type: 'addBlobs', data: n}

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
    p.size(C.X_BOUND, C.Y_BOUND)
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