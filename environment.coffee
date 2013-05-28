class Environment
  @NEIGHBOR_DISTANCE = 100
  @ATTACK_DISTANCE   = 10
  @X_BOUND = 1000
  @Y_BOUND = 1000


  constructor: (nBlobs) ->
    @blobs = {}
    for i in [0...nBlobs]
      position  = Vector2D.randomVector(Environment.X_BOUND, Environment.Y_BOUND)
      @blobs[i] = new Blob(@, position, 100)

  step: () ->
    # placeholder

  calculateNeighbors: (blob) ->
    attackables = []
    neighbors = []
    for (other_id, other_blob) of @blobs
      unless other_id is blob.id
        d = blob.calcDistance(other_blob)
        if d < Environment.ATTACK_DISTANCE
          attackables.push(other_blob)
        if d < Environment.NEIGHBOR_DISTANCE
          neighbors.push([other_blob, d])
    return [attackables, neighbors]
    # O(n) performance - work on this later...

  addChildBlob: (blob, childEnergy) ->
    oldGeneCode = blob.geneCode
    newGeneCode = GeneCode.copy(oldGeneCode)
    


  addNewBlob: (geneCode = null)

