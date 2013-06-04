X_BOUND = 500
Y_BOUND = 500
QTREE_BUCKET_SIZE = 10
NEIGHBOR_DISTANCE = 100
CHILD_DISTANCE    = 30
ATTACK_DISTANCE   = 10

class Environment
  constructor: (starting_blobs, @processing) ->
    @blobs = {}
    @qtree = new QuadTree(X_BOUND, Y_BOUND, QTREE_BUCKET_SIZE)
    @nBlobs = 0
    @nextBlobId = 0
    for i in [0...starting_blobs]
      position  = Vector2D.randomVector(Cons.X_BOUND, Cons.Y_BOUND)
      newBlob = new Blob(@, position, 100)
      @blobs[newBlob.id] = newBlob


  step: () ->
    for id, blob of @blobs
      blob.step()
    if @processing?
      for id, blob of @blobs
        blob.draw(@processing)

  getNeighbors: (blobID) ->
    # Returns a list of [otherBlob, distance, heading] tuples
    # for every other blob less than Cons.NEIGHBOR_DISTANCE away
    neighbors = []
    blobPosition = @qtree.id2point[blobID]
    unless blobPosition?
      throw new Error("Blob position not defined for blob " + blobID)
    for otherID of @qtree.circleQuery(blobPosition, NEIGHBOR_DISTANCE)
      unless other_blob.id is blob.id
        d = blob.calcDistance(other_blob)
        neighbors.push([other_blob, d])
    return neighbors
  
  getAttackables: (blobID) -> 
    attackables = []
    blobPosition = @qtree.id2point(blobID)
    for otherID of @qtree.circleQuery(blobPosition, ATTACKABLE_DISTANCE)
      unless other_blob.id is blob.id
        neighbors.push(other_blob)
    return neighbors

  getHeading: (sourceID, targetID) ->
    sourcePos = @qtree.id2point(sourceID)
    targetPos = @qtree.id2point(targetID)
    Vector2D.subtract(targetPos, sourcePos).heading()

  moveBlob: (blobID, heading, moveAmt) -> 
    sourcePos = @qtree.id2point[blobID]
    moveVector = Vector2D.headingVector(heading).multiply(moveAmt)
    newPos = moveVector.add(sourcePos)
    @qtree.moveObject(blobID, newPos)
    

  addBlob: (energy, geneCode, position) ->
    b = new Blob(@, @nextBlobId, energy, geneCode)
    @blobs[@nextBlobId] = b
    @qtree.addObject(@nextBlobId, position)
    @nextBlobId++
    @nBlobs++

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @qtree.id2point[parentID]
    childOffset = Vector2D.randomUnitVector().multiply(Cons.CHILD_DISTANCE)
    childPosition = childOffset.add(parentPosition)
    @addBlob(childEnergy, childGenes, childPosition)


  removeBlob: (blob) ->
    delete @blobs[blob.id]
    @qtree.removeObject(blob.id)
    @nBlobs--

