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
    for id, blob of @blobs
      blob.preStep()
      blob.chooseAction()

    for id, blob of @blobs
      blob.handleMovement()
    @qtree.rebuild()

    for id, blob of @blobs
      blob.handleAttacks()

    for id, blob of @blobs
      blob.wrapUp()

    @drawAll()


  drawAll: () -> 
    if @p?
      for id, blob of @blobs
        @draw(id, blob)



  draw: (blobID, blob) ->
    @p.noFill()
    @p.noStroke()
    red = blob.atk * 2.55
    grn = blob.pho * 2.55
    blu = blob.spd * 2.55


    @p.fill(red,grn,blu)
    # if blob.rad < C.SMALL_SIZE
    #   @p.fill(255,0,0)
    # else if blob.rad < C.MEDIUM_SIZE
    #   @p.fill(0,255,0)
    # else if blob.rad < C.LARGE_SIZE
    #   @p.fill(0,0,255)
    # else if blob.rad < C.HUGE_SIZE
    #   @p.fill(255,255,0)
    # else
    #   @p.fill(255)
    # @p.strokeWeight(Math.sqrt(blob.energy))
    pos = @qtree.id2point[blobID]
    if blob.observed?
      @p.strokeWeight(1)
      @p.stroke(255)

    @p.ellipse(pos.x, pos.y, 2*blob.rad, 2*blob.rad)

    if blob.reproducing?
      red2 = Math.min red + 9, 255
      grn2 = Math.min grn + 9, 255
      blu2 = Math.min blu + 9, 255
      @p.noFill()
      @p.stroke(red2,grn2,blu2)
      weight = 5 * (C.REPR_TIME_REQUIREMENT - blob.maintainCurrentAction) / C.REPR_TIME_REQUIREMENT
      @p.strokeWeight(weight)
      @p.ellipse(pos.x, pos.y, 2*blob.rad-5, 2*blob.rad-5)

    #make draw wrap-around
    # if pos.x - blob.rad < 0
    #   wrap_x = pos.x + C.X_BOUND
    # if pos.x + blob.rad > C.X_BOUND
    #   wrap_x = pos.x - C.X_BOUND

    # if pos.y - blob.rad < 0
    #   wrap_y = pos.y + C.Y_BOUND
    # if pos.y + blob.rad > C.Y_BOUND
    #   wrap_y = pos.y - C.Y_BOUND

    # if wrap_x or wrap_y
    #   wrap_x ?= pos.x
    #   wrap_y ?= pos.y

    # @p.ellipse(wrap_x, wrap_y, 2*blob.rad, 2*blob.rad)

  getNeighbors: (blobID) ->
    pos = @qtree.id2point[blobID]
    @getAdjacent(pos, C.NEIGHBOR_DISTANCE, blobID)
  
  getAttackables: (blobID) ->
    pos = @qtree.id2point[blobID]
    rad = @blobs[blobID].rad
    @getAdjacent(pos, C.ATTACK_MARGIN + rad, blobID)

  getAdjacent: (position, distance, blobID) ->
    # Returns [adjcentBlob, distance] tuples
    adj = []
    queryResult = @qtree.circleQuery(position, distance)
    for otherID in queryResult
      unless otherID is blobID
        pos2 = @qtree.id2point[otherID]
        d = position.distance(pos2)
        adj.push([@blobs[otherID], d])
    return adj

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



