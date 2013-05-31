class QuadTree
  """Maintain a QuadTree of objects on a 2D space.
  Each object is represented by a unique id and has an associated 2D point.
  Maps from IDs to Vector2D points, and back. 
  Points do not uniquely identify an Id,Point combo because
  multiple IDs may share the same location. IDs
  must be unique."""
  constructor: (@xBound, @yBound, @bucketSize) ->
    @id2point  = {}
    @numPoints = 0
    @tree = new QTNode(@xBound/2, @yBound/2, @xBound/2, @yBound/2, @bucketSize)

  addObject: (id, point) ->
    if id of @id2point
      throw Error("Object ID collision, tried to add id already in map")
    @id2point[id] = point
    @tree.addPoint(id, point)
    ++@numPoints

  removeObject: (id) -> 
    unless id of @id2point
      throw Error("Tried to remove ID that isn't in map")
    p = @id2point[id]
    @tree.removePoint(id, p)
    delete @id2point[id]
    --@numPoints

  moveObject: (id, newPoint) ->
    @removeObject(id)
    @addObject(id, newPoint)
    # Placeholder

  calculateDistance: (id1, id2) -> 
    p1 = @id2point[id1]
    p2 = @id2point[id2]
    p1.eucl_distance(p2)


class QTNode
  constructor: (@x, @y, @xEdge, @yEdge, @bucketSize) ->
    @leaf = true
    @points = {}
    @nPoints = 0

  addPoint: (id, p) ->
    @nPoints++ # Edge case - can nPoints go wrong if colliding IDs are added to QT? 
    if @leaf
      @points[id] = p
      if @nPoints > @bucketSize
        @leaf = false
        newXEdge = @xEdge / 2
        newYEdge = @yEdge / 2
        MM = new QTNode(@x - newXEdge, @y - newYEdge, newXEdge, newYEdge, @bucketSize)
        MP = new QTNode(@x - newXEdge, @y + newYEdge, newXEdge, newYEdge, @bucketSize)
        PM = new QTNode(@x + newXEdge, @y - newYEdge, newXEdge, newYEdge, @bucketSize)
        PP = new QTNode(@x + newXEdge, @y + newYEdge, newXEdge, newYEdge, @bucketSize)
        @children = [MM, MP, PM, PP]
        @addPoint(id_, p_) for id_, p_ of @points
        delete @points
    else
      # 0 -> MM, 1 -> MP, 2 -> PM, 3 -> PP
      idx = 2 * (p.x > @x) + (p.y > @y)
      @children[idx].addPoint(id, p)

  removePoint: (id, p) ->
    if @leaf
      unless id of @points
        throw new Error("Tried to remove id not in QTNode")
      delete @points[id]
      --@nPoints
    else
      idx = 2 * (p.x > @x) + (p.y > @y)
      @children[idx].removePoint(id, p)

