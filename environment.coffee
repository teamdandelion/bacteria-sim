class Environment
  constructor: (@nBlobs=0) ->
    @blobs = {}
    for i in [0...nBlobs]
      position  = Vector2D.randomVector(Cons.x_bound, Cons.y_bound)
      newBlob = new Blob(@, position, 100)
      @blobs[newBlob.id] = newBlob


  step: () ->
    for id, blob of @blobs
      neighbors = @calculateNeighbors(blob)
      blob.step(neighbors)
    console.log @nBlobs


  calculateNeighbors: (blob) ->
    attackables = []
    neighbors = []
    for other_id, other_blob of @blobs
      unless other_id is blob.id
        d = blob.calcDistance(other_blob)
        if d < Cons.attack_distance
          attackables.push(other_blob)
        if d < Cons.neighbor_distance
          neighbors.push([other_blob, d])
    return [attackables, neighbors]
    # O(n) performance - work on this later...

  addBlob: (newBlob) ->
    @blobs[newBlob.id] = newBlob
    @nBlobs++


  removeBlob: (blob) ->
    delete @blobs[blob.id]
    @nBlobs--

e = new Environment(5)
for i in [0..100]
  e.step()