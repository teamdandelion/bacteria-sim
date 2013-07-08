class C
  # Environment variables

  @X_BOUND = $(window).width()
  @Y_BOUND = $(window).height()
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = off # change display bound if you turn this on
  
  @TWO_TRADEOFF = off
  @HARSH_REPRODUCTION = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 20
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 100
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100

  @REPR_ENERGY_COST    = 2000
  @MOVEMENT_SPEED_FACTOR = .3
  @PHO_EPS =  .05
  @PHO_SQ_EPS = .15
  @ATK_EPS = -.5
  @ATK_SQ_EPS = 0
  @SPD_EPS = 0
  @AGE_ENERGY_DECAY = .5
  @RADIUS_FACTOR = .1
  @RADIUS_CONSTANT = 1 
  @BLOB_SIZE = 1.0 # single scaling factor
  @ENERGY_DECAY = .005
  @REPR_TIME_REQUIREMENT = 7

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 60
  @MOVE_UPDATE_AMT = 5
WAIT_FACTOR = 1.1

class Renderer
  # Renders blobs
  constructor: (@frontend, @p) ->
    @frames = 0
    @frameRate = C.FRAME_RATE
    @framesUntilUpdate = 1
    @colors = {} # map from ID -> [r,g,b]
    @futureColors = {}
    @currentState = {} # Map from ID -> [x,y,size]
    @futureState = {}  # Map from ID -> [x,y,size]
    @delta = {}        # Map from ID -> [x,y,size]

    @updateAvailable = no
    @update = []
    @thunks = 0
    @requestUpdate()
    @lastFrame = Date.now()
    @removedLastStep = []

  step: () ->
    @frames++
    currentTime = Date.now()
    # console.log "Time since last frame: #{currentTime - @lastFrame}"
    @lastFrame = currentTime
    if @framesUntilUpdate == 0
      if @updateAvailable
        if @thunks > 0
          WAIT_FACTOR += .05
          WAIT_FACTOR *= 1.05
          console.log "Thunked #{@thunks} times"
          @thunks = 0
        @processUpdate()
      else
        @thunks++

    unless @thunks
      @drawAll()

  drawBlob: (state, color) -> 
    [x,y,r] = state
    [red, grn, blu] = color
    
    @p.noStroke()
    @p.fill(red,grn,blu)
    @p.ellipse(x, y, 2*r, 2*r)

  drawAll: () ->
    @p.background(0,40,0)
    for id, state of @currentState
      state[0] += @delta[id][0]
      state[1] += @delta[id][1]
      state[2] += @delta[id][2]
      @drawBlob(state, @colors[id])
    --@framesUntilUpdate



  requestUpdate: () ->
    @requestTime = Date.now()
    @frontend.requestUpdate()

  receiveUpdate: (@update) ->
    # console.log "Got update"
    @timeElapsed = Date.now() - @requestTime
    @updateAvailable = yes


  processUpdate: () -> 
    @updateAvailable = no
    @requestUpdate()
    @currentState = @futureState
    # The current state for this turn is the last turn's future state
    # The reason for doing this instead of continuing to update the 
    # currentState instance we already have is that float addition
    # errors might grow over time so that the renderer would go out
    # of sync with the simulation
    @futureState  = @update.blobs   # {id -> [x,y,r]}
    removedBlobs  = @update.removed #[id]
    addedBlobs    = @update.added   # {id -> color}






    for id, c of addedBlobs
      @colors[id] = c
    for id in @removedLastStep 
    # We don't remove the color on the turn in which they're removed, becuse
    # we need to render them getting smaller. After they've visually disappeared,
    # we delete from the dict to avoid a memory leak
      delete @colors[id]
      

    @framesUntilUpdate = Math.ceil(WAIT_FACTOR * @timeElapsed / @frameRate)
    if @framesUntilUpdate < 4
      @framesUntilUpdate = 4
    # console.log @timeElapsed, @frameRate, @timeElapsed / @frameRate
    # console.log "FUU: " + @framesUntilUpdate
    for id, [xf,yf,rf] of @futureState
      unless id of @currentState
        @currentState[id] = [xf, yf, 0]

      [xc,yc,rc] = @currentState[id]
      dx = (xf - xc) / @framesUntilUpdate
      dy = (yf - yc) / @framesUntilUpdate
      dr = (rf - rc) / @framesUntilUpdate
      @delta[id] = [dx, dy, dr]

    for id in removedBlobs
      # console.log @frames, id, @currentState[id]
      if id of @currentState

        dr = -@currentState[id][2] / @framesUntilUpdate
        @delta[id] = [0,0,dr]
      else 
        # This generally means that a blog was added and died within a single update
        console.log "blob #{id} was listed as removed but not found in state" 
    @removedLastStep = removedBlobs



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
    @addBlobs(C.STARTING_BLOBS)
    @renderer = new Renderer(@, @p)
    @running = on
    $(window).resize(
      () => 
        console.log "Resizing"
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
    opt['Kill most blobs'] = () => 
      @sim.postMessage {type: 'killMostBlobs'}
    opt['Add a blob'] = () =>
      @sim.postMessage {type: 'addRandomBlob'}

    
    gui = new dat.GUI()

    addSlider = (name, min, max, step) => 
      step ?= (max-min)/100
      gui.add(C, name, min, max, step).onFinishChange(
        (newVal) => @updateConstants()
        )
    addSlider('REPR_ENERGY_COST', 100, 2000)
    addSlider('PHO_EPS', 0, 1.0)
    addSlider('PHO_SQ_EPS', 0, .2)
    addSlider('ATK_EPS', -1.0, 1.0)
    addSlider('ATK_SQ_EPS', -.2, .2)
    addSlider('BLOB_SIZE', 0.1, 5)
    addSlider('MUTATION_CONSTANT', .01, 1)
    addSlider('MUTATION_PROBABILITY', 0, .5)
    addSlider('ENERGY_DECAY', 0, .1)
    addSlider('AGE_ENERGY_DECAY', 0, 1)
    gui.add(opt, 'Kill all blobs')
    gui.add(opt, 'Add a blob')
    gui.add(opt, 'Kill most blobs')

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