class Environment
  constructor: (@nBlobs=0, @processing) ->
    @blobs = {}
    for i in [0...nBlobs]
      position  = Vector2D.randomVector(Cons.X_BOUND, Cons.Y_BOUND)
      newBlob = new Blob(@, position, 100)
      @blobs[newBlob.id] = newBlob


  step: () ->
    for id, blob of @blobs
      blob.step()
    if @processing?
      for id, blob of @blobs
        blob.draw(@processing)

  calculateNeighbors: (blob) ->
    # Returns a list of [otherBlob, distance] tuples
    # for every other blob less than Cons.NEIGHBOR_DISTANCE away
    neighbors = []
    for other_id, other_blob of @blobs
      unless other_blob.id is blob.id
        d = blob.calcDistance(other_blob)
        if d is 0
          console.log "Something probably went wrong"
        if d < Cons.NEIGHBOR_DISTANCE
          neighbors.push([other_blob, d])
    return neighbors
    # O(n) performance - work on this later...

  addBlob: (newBlob) ->
    @blobs[newBlob.id] = newBlob
    @nBlobs++


  removeBlob: (blob) ->
    delete @blobs[blob.id]
    @nBlobs--

