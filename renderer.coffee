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

  draw: () ->
    if @framesUntilNextDraw == 0
      if @updateAvailable
        if @thunks > 0
          console.log "Thunked #{@thunks} times"
          @thunks = 0
        @processUpdate()
      else
        @thunks++


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
            @currentState[id] = [blob.pos.x, blob.pos.y, blob.rad]
            

            @delta[id] = []
        

  requestUpdate: () ->
    @requestTime = Date.now()
    @frontend.requestUpdate()

  recieveUpdate: (@update) ->
    @timeElapsed = Date.now() - @requestTime
    @updateAvailable = yes

  computeDelta: () ->



  draw: (blobs) -> 
    @p.background(0)
    for blobID, blob of blobs
      
      @drawBlob(blob, blob.pos)
    if C.INFO_WINDOW then @infoArea.draw()


  drawBlob: (blob, position) -> 
    r = blob.rad
    x = position.x
    y = position.y
    # These are coordinates relative to the upper-left
    # hand corner of the viewing area
    intersectX = x+r > @xLower or x-r < @xUpper
    intersectY = y+r > @yLower or y-r < @yUpper
    if intersectX and intersectY
      x-= @xLower
      y-= @yLower
      @p.noStroke()

      
      red = blob.atk * 2.55
      grn = blob.pho * 2.55
      blu = blob.spd * 2.55
      @p.fill(red,grn,blu)

      # if blob.observed?
      #   @p.strokeWeight(1)
      #   @p.stroke(255)
      
      @p.ellipse(x, y, 2*r, 2*r)

      # # nucleus colors
      # if @showNucleus
      #   nuc_red = blob.red
      #   nuc_grn = blob.grn
      #   nuc_blu = blob.blu
      #   @p.fill(nuc_red,nuc_grn,nuc_blu)
      #   rad = Math.min(3, blob.rad/2)
      #   @p.ellipse(x,y,2*rad, 2*rad)

      # if @showShells
      #   nuc_red = blob.red
      #   nuc_grn = blob.grn
      #   nuc_blu = blob.blu
      #   @p.stroke(nuc_red,nuc_grn,nuc_blu)
      #   @p.noFill()
      #   rad = blob.rad
      #   @p.strokeWeight(2)
      #   @p.ellipse(x,y,2*rad, 2*rad)


      # if @showReproduction and blob.reproducing?
      #   red2 = Math.min red + 9, 255
      #   grn2 = Math.min grn + 9, 255
      #   blu2 = Math.min blu + 9, 255
      #   @p.noFill()
      #   @p.stroke(red2,grn2,blu2)
      #   weight = 5 * (C.REPR_TIME_REQUIREMENT - blob.maintainCurrentAction) / C.REPR_TIME_REQUIREMENT
      #   @p.strokeWeight(weight)
      #   @p.ellipse(x, y, 2*r-5, 2*r-5)