X_BOUND = 500
Y_BOUND = 500
QTREE_BUCKET_SIZE = 100
NEIGHBOR_DISTANCE = 100
CHILD_DISTANCE    = 100
ATTACK_DISTANCE   = 20
STARTING_ENERGY   = 500

class Environment
  constructor: (starting_blobs, @processing) ->
    @blobs = {}
    @qtree = new QuadTree(X_BOUND, Y_BOUND, QTREE_BUCKET_SIZE)
    @nBlobs = 0
    @nextBlobId = 0
    for i in [0...starting_blobs]
      position  = Vector2D.randomVector(X_BOUND, Y_BOUND)
      @addBlob(position, STARTING_ENERGY)

  step: () ->
    for id, blob of @blobs
      blob.step()

    if @processing?
      for id, blob of @blobs
        @draw(id, blob)
    @qtree.rebuild()

  draw: (blobID, blob) ->
    @processing.stroke(blob.atk*2.55,blob.pho*2.55,blob.spd*2.55)
    @processing.strokeWeight(5)
    position = @qtree.id2point[blobID]
    @processing.point(position.x, position.y)

  getNeighbors: (blobID) ->
    @getAdjacent(blobID, NEIGHBOR_DISTANCE)
  
  getAttackables: (blobID) -> 
    @getAdjacent(blobID, ATTACK_DISTANCE)

  getAdjacent: (blobID, distance) ->
    # Returns [adjcentBlob, distance] tuples
    adj = []
    blobPosition = @qtree.id2point[blobID]
    queryResult = @qtree.quickQuery(blobPosition, distance)
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
    @qtree.moveObject(blobID, newPos)
    

  addBlob: (position, energy, geneCode) ->
    b = new Blob(@, @nextBlobId, energy, geneCode)
    @blobs[@nextBlobId] = b
    @qtree.addObject(@nextBlobId, position)
    @nextBlobId++
    @nBlobs++

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @qtree.id2point[parentID]
    childOffset = Vector2D.randomUnitVector().multiply(CHILD_DISTANCE)
    childPosition = childOffset.add(parentPosition)
    if 0<childPosition.x<X_BOUND and 0<childPosition.y<Y_BOUND
      @addBlob(childPosition, childEnergy, childGenes)

  removeBlob: (blobID) ->
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @nBlobs--

  getDistance: (ID1, ID2) -> 
    v1 = @qtree.id2point[ID1]
    v2 = @qtree.id2point[ID2]
    v1.distance(v2)


