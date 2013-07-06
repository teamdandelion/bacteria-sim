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
    @p.background(0)
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
    # console.log "Processing update"
    @updateAvailable = no
    @requestUpdate()
    @currentState = @futureState
    @futureState = @update.blobs
    removedBlobs = @update.removed
    addedBlobs = @update.added

    for id, c of addedBlobs
      @colors[id] = c
    for id in @removedLastStep
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
      dx = xf - xc
      dy = yf - yc
      dr = (rf - rc) / @framesUntilUpdate
      @delta[id] = [dx, dy, dr]

    for id in removedBlobs
      # console.log @frames, id, @currentState[id]
      dr = -@currentState[id][2] / @framesUntilUpdate
      @delta[id] = [0,0,dr] 
    @removedLastStep = removedBlobs



