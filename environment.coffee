class Environment
  constructor: (starting_blobs, @p) ->
    @blobs = {}
    @qtree = new QuadTree(C.X_BOUND, C.Y_BOUND, C.QTREE_BUCKET_SIZE)
    @nBlobs = 0
    @nextBlobId = 0
    @observedBlobID = null
    for i in [0...starting_blobs]
      position  = Vector2D.randomVector(C.X_BOUND, C.Y_BOUND)
      @addBlob(position, C.STARTING_ENERGY)

  observeBlob: (xCoord, yCoord) -> 
    console.log "Called observeBlob with " + xCoord + "," + yCoord
    clickLocation = new Vector2D(xCoord, yCoord)
    # find closest blob to the click
    if @observedBlob?
      prevId = @observedBlob.id
      @observedBlob.observed = null
      @observedBlob = null
    nearbyBlobs = @getAdjacent(clickLocation, 30)
    selected = minByIndex(nearbyBlobs, 1)
    if selected?
      selected = selected[0]
    if selected? and selected.id != prevId
      @observedBlob = selected
      console.log "Observing blob:" + @observedBlob.id
      @observedBlob.observed = on

  step: () ->
    @qtree.rebuild()
    for id, blob of @blobs
      blob.preStep()
      blob.chooseAction()

    for id, blob of @blobs
      blob.handleMovement()

    for id, blob of @blobs
      blob.handleAttacks()

    for id, blob of @blobs
      blob.wrapUp()


  getNeighbors: (blobID) ->
    pos = @qtree.id2point[blobID]
    rad = @blobs[blobID].rad
    @getAdjacent(pos, C.NEIGHBOR_DISTANCE + rad * 1.5, blobID)

  getAdjacent: (position, distance, blobID) ->
    # Returns nearby blobs
    queryResult = @qtree.approximateCircleQuery(position, distance)
    (@blobs[otherID] for otherID in queryResult when otherID != blobID)


  getHeading: (sourceID, targetID) ->
    sourcePos = @qtree.id2point[sourceID]
    targetPos = @qtree.id2point[targetID]
    Vector2D.subtract(targetPos, sourcePos).heading()

  moveBlob: (blobID, heading, moveAmt) -> 
    sourcePos = @qtree.id2point[blobID]
    moveVector = Vector2D.headingVector(heading).multiply(moveAmt)
    newPos = moveVector.add(sourcePos)
    newPos.wrapToBound(C.X_BOUND, C.Y_BOUND)
    @qtree.moveObject(blobID, newPos)
    

  addBlob: (position, energy, geneCode) ->
    b = new Blob(@, @nextBlobId, energy, geneCode)
    @blobs[@nextBlobId] = b
    @qtree.addObject(@nextBlobId, position)
    @nextBlobId++
    @nBlobs++

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @qtree.id2point[parentID]
    parentRadius = @blobs[parentID].rad
    childOffset = Vector2D.randomUnitVector()
    childOffset.multiply(C.CHILD_DISTANCE + parentRadius)
    childPosition = childOffset.add(parentPosition)
    childPosition.wrapToBound(C.X_BOUND, C.Y_BOUND)
    @addBlob(childPosition, childEnergy, childGenes)

  removeBlob: (blobID) ->
    if @observedBlob? and @observedBlob.id == blobID
      @observedBlob = null
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @nBlobs--

  isAlive: (blobID) -> 
    blobID of @blobs

  blobDistSq: (blob1, blob2) ->
    p1 = @qtree.id2point[blob1.id]
    p2 = @qtree.id2point[blob2.id]
    p1.distSq(p2)

  blobDist: (blob1, blob2) ->
    Math.sqrt @blobDistSq(blob1, blob2)



