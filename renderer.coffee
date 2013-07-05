class Renderer
  # Renders blobs
  constructor: (@frontend, @p) ->
    @frameRate = C.FRAME_RATE
    @framesUntilNextDraw = 0
    @colors = {} # map from ID -> [r,g,b]
    @futureColors = {}
    @currentState = {} # Map from ID -> [x,y,size]
    @futureState = {}  # Map from ID -> [x,y,size]
    @delta = {}        # Map from ID -> [x,y,size]

    @updateAvailable = no
    @update = []
    @thunks = 0

  step: () ->
    if @framesUntilNextDraw == 0
      if @updateAvailable
        if @thunks > 0
          console.log "Thunked #{@thunks} times"
          @thunks = 0
        @processUpdate()
      else
        @thunks++

    unless @thunks
      @drawAll()

  drawAll: () ->
    @p.background(0)
    for id, state of @currentState
      state[0] += @delta[id][0]
      state[1] += @delta[id][1]
      state[2] += @delta[id][2]
      drawBlob(state, @colors[id])
    --@framesUntilNextDraw

  drawBlob: ([x,y,r],[red,grn,blu]) -> 
    intersectX = x+r > @xLower or x-r < @xUpper
    intersectY = y+r > @yLower or y-r < @yUpper
    if intersectX and intersectY
      x-= @xLower
      y-= @yLower
      @p.noStroke()

      @p.fill(red,grn,blu)
      
      @p.ellipse(x, y, 2*r, 2*r)




  processUpdate: () -> 
  @updateAvailable = no
  @requestUpdate()
  @currentState = @futureState
  @futureState = []
  @colors = @futureColors
  @futureColors = []
  [futureBlobs, removedBlobs] = @update
  for id, blob of futureBlobs
    @futureState[id]  = [blob.pos.x, blob.pos.y, blob.rad]
    @futureColors[id] = [blob.red, blob.grn, blob.blu]

  @framesUntilNextDraw = Math.ceil(1.1 * @timeElapsed / @frameRate)
  for id, blob of futureBlobs
    unless id in @currentState
      @currentState[id] = [blob.pos.x, blob.pos.y, 0]
      @colors[id] = [blob.red, blob.grn, blob.blu]

    x,y,r = @currentState[id]
    dx = (blob.pos.x - x) / @framesUntilNextDraw
    dy = (blob.pos.y - y) / @framesUntilNextDraw
    dr = (blob.pos.r - r) / @framesUntilNextDraw
    @delta[id] = [dx, dy, dr]

  for id in removedBlobs
    dr = -@currentState[id][2] / @framesUntilNextDraw
    @delta[id] = [0,0,dr] 

  requestUpdate: () ->
    @requestTime = Date.now()
    @frontend.requestUpdate()

  recieveUpdate: (@update) ->
    @timeElapsed = Date.now() - @requestTime
    @updateAvailable = yes


