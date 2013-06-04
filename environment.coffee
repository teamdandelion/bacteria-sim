class Environment
  constructor: (starting_blobs, @processing) ->
    @blobs = {}
    @qtree = new QuadTree(C.X_BOUND, C.Y_BOUND, C.QTREE_BUCKET_SIZE)
    @nBlobs = 0
    @nextBlobId = 0
    for i in [0...starting_blobs]
      position  = Vector2D.randomVector(C.X_BOUND, C.Y_BOUND)
      @addBlob(position, C.STARTING_ENERGY)

  step: () ->
    for id, blob of @blobs
      blob.step()

    if @processing?
      for id, blob of @blobs
        @draw(id, blob)
    @qtree.rebuild()

  draw: (blobID, blob) ->
    @processing.fill(blob.atk*2.55,blob.pho*2.55,blob.spd*2.55)
    # @processing.strokeWeight(Math.sqrt(blob.energy))
    pos = @qtree.id2point[blobID]
    @processing.ellipse(pos.x, pos.y, 2*blob.rad, 2*blob.rad)
    # @processing.point(position.x, position.y)

  getNeighbors: (blobID) ->
    @getAdjacent(blobID, C.NEIGHBOR_DISTANCE)
  
  getAttackables: (blob) ->
    rad = blob.rad
    @getAdjacent(blob.id, C.ATTACK_MARGIN + rad)

  getAdjacent: (blobID, distance) ->
    # Returns [adjcentBlob, distance] tuples
    adj = []
    blobPosition = @qtree.id2point[blobID]
    queryResult = @qtree.circleQuery(blobPosition, distance)
    for otherID in queryResult
      unless otherID is blobID
        d = @getDistance(blobID, otherID)
        adj.push([@blobs[otherID], d])
    return adj

  getHeading: (sourceID, targetID) ->
    sourcePos = @qtree.id2point(sourceID)
    targetPos = @qtree.id2point(targetID)
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
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @nBlobs--

  getDistance: (ID1, ID2) -> 
    v1 = @qtree.id2point[ID1]
    v2 = @qtree.id2point[ID2]
    v1.distance(v2)


