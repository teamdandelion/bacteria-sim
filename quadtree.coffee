class QuadTree
  """Maintain a QuadTree of objects on a 2D space.
  Each object is represented by a unique id and has an associated 2D point.
  Maps from IDs to Vector2D points, and back. 
  Points do not uniquely identify an Id,Point combo because
  multiple IDs may share the same location. IDs
  must be unique.
  NOTE: QuadTree may break if >bucketSize points have exact same coordinate
  Suggest fixing by adding tiny random disturbance to avoid this situation"""
  constructor: (@xBound, @yBound, @bucketSize) ->
    @id2point  = {}
    @numPoints = 0
    @tree = new QTNode(@xBound/2, @yBound/2, @xBound/2, @yBound/2, @bucketSize)

  addObject: (id, point) ->
    if not (0<point.x<@xBound and 0<point.y<@yBound)
      throw new Error("Index out of bounds: #{point.x}, #{point.y}")
    if id of @id2point and not @rebuilding
      throw Error("Object ID collision on id: " + id)
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

  circleQuery: (centerPoint, radius) -> 
    """Returns a list of all object IDs that fall within the circle"""
    @tree.circleQuery centerPoint, radius, radius*radius

  approximateCircleQuery: (centerPoint, radius) -> 
    """Returns a list of all object IDs that fall in nodes that intersect the circle"""
    @tree.approximateCircleQuery centerPoint, radius, radius*radius
    

  rebuild: () ->
    @rebuilding = on
    @tree = new QTNode(@xBound/2, @yBound/2, @xBound/2, @yBound/2, @bucketSize)
    for id, pt of @id2point
      @addObject id, pt
    @rebuilding = off

class QTNode
  constructor: (@x, @y, @xEdge, @yEdge, @bucketSize, @depth=0) ->
    @leaf = true
    @points = {}
    @nPoints = 0
    MM = new Vector2D(@x - @xEdge, @y - @yEdge)
    MP = new Vector2D(@x - @xEdge, @y + @yEdge)
    PM = new Vector2D(@x + @xEdge, @y - @yEdge)
    PP = new Vector2D(@x + @xEdge, @y + @yEdge)
    @corners = [MM, MP, PM, PP]

  addPoint: (id, p) ->
    @nPoints++ # Edge case - can nPoints go wrong if colliding IDs are added to QT? 
    @points[id] = p
    if @leaf
      if @nPoints > @bucketSize
        @leaf = false
        @createChildren()
        @nPoints = 0
        pts = @points
        @points = {}
        @addPoint(id_, p_) for id_, p_ of pts
    else
      # 0 -> MM, 1 -> MP, 2 -> PM, 3 -> PP
      idx = 2 * (p.x > @x) + (p.y > @y)
      @children[idx].addPoint(id, p)

  createChildren: () -> 
    if @children?
      throw new Error("Non-leaf node tried to make children")
    newXEdge = @xEdge / 2
    newYEdge = @yEdge / 2
    if @depth > 4000
      console.log @points
    MM = new QTNode(@x - newXEdge, @y - newYEdge, newXEdge, newYEdge, @bucketSize, @depth+1)
    MP = new QTNode(@x - newXEdge, @y + newYEdge, newXEdge, newYEdge, @bucketSize, @depth+1)
    PM = new QTNode(@x + newXEdge, @y - newYEdge, newXEdge, newYEdge, @bucketSize, @depth+1)
    PP = new QTNode(@x + newXEdge, @y + newYEdge, newXEdge, newYEdge, @bucketSize, @depth+1)
    @children = [MM, MP, PM, PP]
      

  removePoint: (id, p) ->
    unless id of @points
      throw new Error("Tried to remove id not in QTNode")
    delete @points[id]
    --@nPoints
    unless @leaf
      idx = 2 * (p.x > @x) + (p.y > @y)
      @children[idx].removePoint(id, p)

  nearbyPoints: (centerPoint, maxDist) -> 
    if @leaf
      distSq = maxDist * maxDist
      parent = @parent ? @
      grandparent = parent.parent ? parent
      pts = grandparent.points
      (id for id, pt of pts when centerPoint.distSq(pt) <= distSq)
    else
      idx = 2 * (centerPoint.x > @x) + (centerPoint.y > @y)
      @children[idx].nearbyPoints(centerPoint, maxDist)


  circleQuery: (centerPoint, radius, radiusSq) ->
    # recurse thru list of QTNodes which intersect this circle
    # radiusSq = radius^2 so we can avoid sqrt calculations

    intersect = false
    xDist = Math.abs(centerPoint.x-@x)
    yDist = Math.abs(centerPoint.y-@y)
    intersect ||= xDist <= @xEdge and yDist <= @yEdge + radius # intersects top or bottom of rect
    intersect ||= yDist <= @yEdge and xDist <= @xEdge + radius # intersects left or right of rect
    minDist2Corner = Math.min (centerPoint.distSq c for c in @corners)...
    intersect ||= minDist2Corner <= radiusSq
    if intersect
      if @leaf 
        (id for id, pt of @points when centerPoint.distSq(pt) <= radiusSq)
      else 
        [].concat (c.circleQuery(centerPoint, radius, radiusSq) for c in @children)...
    else
      []

  approximateCircleQuery: (centerPoint, radius, radiusSq) ->
    intersect = false
    xDist = Math.abs(centerPoint.x-@x)
    yDist = Math.abs(centerPoint.y-@y)
    intersect ||= xDist <= @xEdge and yDist <= @yEdge + radius # intersects top or bottom of rect
    intersect ||= yDist <= @yEdge and xDist <= @xEdge + radius # intersects left or right of rect
    minDist2Corner = Math.min (centerPoint.distSq c for c in @corners)...
    intersect ||= minDist2Corner <= radiusSq
    if intersect
      if @leaf 
        (id for id, pt of @points)
      else 
        [].concat (c.approximateCircleQuery(centerPoint, radius, radiusSq) for c in @children)...
    else
      []

    
