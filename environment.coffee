class Environment
  @NEIGHBOR_DISTANCE = 500
  @ATTACK_DISTANCE   = 50

  constructor: (nBlobs) ->
    @blobs = {}
    for i in [0...nBlobs]
      genes = 
      @blobs[i] = 

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

