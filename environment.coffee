class Environment
  constructor: (starting_blobs, @p) ->
    @blobs = {}
    @qtree = new QuadTree(C.X_BOUND, C.Y_BOUND, C.QTREE_BUCKET_SIZE)
    @location = @qtree.id2point
    @nBlobs = 0
    @nextBlobId = 0
    @observedBlobID = null
    @total_red = 0
    @total_grn = 0
    @total_blu = 0
    for i in [0...starting_blobs]
      @addRandomBlob()

  observeBlob: (xCoord, yCoord) -> 
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
    pos = @location[blobID]
    rad = @blobs[blobID].rad
    @getAdjacent(pos, C.NEIGHBOR_DISTANCE + rad * 1.5, blobID)

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
    newPos.wrapToBound(C.X_BOUND, C.Y_BOUND)
    @qtree.moveObject(blobID, newPos)
    

  addBlob: (position, energy, geneCode) ->
    b = new Blob(@, @nextBlobId, energy, geneCode)
    @blobs[@nextBlobId] = b
    @qtree.addObject(@nextBlobId, position)
    @nextBlobId++
    @nBlobs++
    @total_red += b.redSq
    @total_grn += b.grnSq
    @total_blu += b.bluSq

  addRandomBlob: () -> 
    pos = Vector2D.randomBoundedVector(C.X_MARGIN, C.DISPLAY_X + C.X_MARGIN,
                                       C.Y_MARGIN, C.DISPLAY_Y + C.Y_MARGIN)
    @addBlob(pos, C.STARTING_ENERGY)

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @location[parentID]
    parentRadius = @blobs[parentID].rad
    childOffset = Vector2D.randomUnitVector()
    childOffset.multiply(C.CHILD_DISTANCE + parentRadius)
    childPosition = childOffset.add(parentPosition)
    childPosition.wrapToBound(C.X_BOUND, C.Y_BOUND)
    @addBlob(childPosition, childEnergy, childGenes)

  removeBlob: (blobID) ->
    if @observedBlob? and @observedBlob.id == blobID
      @observedBlob = null
    b = @blobs[blobID]
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @nBlobs--
    @total_red -= b.redSq
    @total_grn -= b.grnSq
    @total_blu -= b.bluSq

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



