WAIT_FACTOR = 1.1

class Renderer
  # Renders blobs
  constructor: (@frontend, @p) ->
    @frames = 0
    @frameRate = @frontend.C.FRAME_RATE
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



