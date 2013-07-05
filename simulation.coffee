class Simulation
  constructor: () ->
    # Do nothing; we need to wait for an initialization message that contains the C (Constants) data object
    @initialized = off

  initialize: () -> 
    @initialized = on
    @blobs = {}
    @qtree = new QuadTree(self.C.X_BOUND, self.C.Y_BOUND, self.C.QTREE_BUCKET_SIZE)
    @location = @qtree.id2point
    @nBlobs = 0
    @nextBlobId = 0
    @observedBlobID = null
    @blobsRemovedThisStep = []
    @blobsAddedThisStep = {}

  processMessage: (msg) ->
    unless @initialized or msg.type == "updateConstants"
      self.postDebug "Recieved msg #{msg} while uninitialized"
      return
    switch msg.type
      when "go"
        @step()
        @postBlobData()
        
      when "killAllBlobs"
        @killAllBlobs()
      
      when "addRandomBlob"
        @addRandomBlob()
      
      when "addBlobs"
        for i in [0...msg.data]
          @addRandomBlob()

      when "updateConstants"
        self.C = msg.data
        unless @initialized
          @initialize()

  postBlobData: () ->
    blobStates = {}
    for id, blob of @blobs
      blobStates[id] = [blob.pos.x, blob.pos.y, blob.rad]
    msg = {
      type: 'blobs'
      blobs: blobStates
      added: @blobsAddedThisStep
      removed: @blobsRemovedThisStep
    }
    postMessage(msg)

  observeBlob: (xCoord, yCoord) -> 
    console.log "Called observeBlob with " + xCoord + "," + yCoord
    clickLocation = new Vector2D(xCoord, yCoord)
    # find closest blob to the click
    if @observedBlob?
      prevId = @observedBlob.id
      @observedBlob.observed = null
      @observedBlob = null
    nearbyBlobs = @getAdjacent(clickLocation, 80)
    nearbyBlobs = ([b, clickLocation.distSq(@location[b.id])] for b in nearbyBlobs)
    selected = minByIndex(nearbyBlobs, 1)
    if selected? and selected[1] < selected[0].rad + 10 and selected[0].id != prevId
      selected = selected[0]
      @observedBlob = selected
      console.log "Observing blob:" + @observedBlob.id
      # console.log @observedBlob
      @observedBlob.observed = on

  step: () ->
    @blobsRemovedThisStep = []
    @qtree.rebuild()
    for id, blob of @blobs
      blob.preStep()
      blob.chooseAction()

    for id, blob of @blobs
      blob.handleMovement()

    for id, blob of @blobs
      blob.handleAttacks()

    for id, blob of @blobs
      blob.wrapUp(@location[id])

  getNeighbors: (blobID) ->
    pos = @location[blobID]
    rad = @blobs[blobID].rad
    @getAdjacent(pos, self.C.NEIGHBOR_DISTANCE + rad * 1.5, blobID)

  getAdjacent: (position, distance, blobID) ->
    # Returns nearby blobs
    queryResult = @qtree.approximateCircleQuery(position, distance)
    (@blobs[otherID] for otherID in queryResult when otherID != blobID)


  getHeading: (sourceID, targetID) ->
    sourcePos = @location[sourceID]
    targetPos = @location[targetID]
    Vector2D.subtract(targetPos, sourcePos).heading()

  moveBlob: (blobID, heading, moveAmt) -> 
    sourcePos = @location[blobID]
    moveVector = Vector2D.headingVector(heading).multiply(moveAmt)
    newPos = moveVector.add(sourcePos)
    newPos.wrapToBound(self.C.X_BOUND, self.C.Y_BOUND)
    @qtree.moveObject(blobID, newPos)
    

  addBlob: (position, energy, geneCode) ->
    b = new Blob(@, @nextBlobId, energy, geneCode, position)
    @blobs[@nextBlobId] = b
    @blobsAddedThisStep[@nextBlobId] = [b.red, b.grn, b.blu]
    @qtree.addObject(@nextBlobId, position)
    @nextBlobId++
    @nBlobs++

  addRandomBlob: () -> 
    pos = Vector2D.randomBoundedVector(self.C.X_MARGIN, self.C.DISPLAY_X + self.C.X_MARGIN,
                                       self.C.Y_MARGIN, self.C.DISPLAY_Y + self.C.Y_MARGIN)
    @addBlob(pos, self.C.STARTING_ENERGY)

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @location[parentID]
    parentRadius = @blobs[parentID].rad
    parentSpeed = @blobs[parentID].spd
    childOffset = Vector2D.randomUnitVector()
    childOffset.multiply(self.C.CHILD_DISTANCE + parentRadius + parentSpeed / 2)
    childPosition = childOffset.add(parentPosition)
    childPosition.wrapToBound(self.C.X_BOUND, self.C.Y_BOUND)
    @addBlob(childPosition, childEnergy, childGenes)

  removeBlob: (blobID) ->
    if @observedBlob? and @observedBlob.id == blobID
      @observedBlob = null
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @blobsRemovedThisStep.push blobID
    @nBlobs--

  killAllBlobs: () ->
    for blobID, blob of @blobs
      @removeBlob(blobID)

  isAlive: (blobID) -> 
    blobID of @blobs

  blobDistSq: (blob1, blob2) ->
    p1 = @location[blob1.id]
    p2 = @location[blob2.id]
    p1.distSq(p2)

  blobDist: (blob1, blob2) ->
    Math.sqrt @blobDistSq(blob1, blob2)

self.postDebug = (msg) ->
  postMessage {
    type: 'debug'
    msg: msg
  }

sim = new Simulation()
@onmessage = (event) => 
  sim.processMessage(event.data)

