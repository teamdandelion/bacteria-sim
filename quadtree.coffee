class QuadTree
  """Maintain a QuadTree of points on a 2D space.
  The points are assumed to have a 'position' attribute
  which is a vector object; the 'position' attribute should
  have 'x' and 'y' attributes which are numbers."""
  QuadTree.maxPointsPerLeaf = 20
  constructor: (@x, @y, @edgeDist) ->
    @leaf = true
    @points = []
    @nChildPoints = 0

  addPoint: (p) ->
    @nChildPoints++
    if @leaf
      @points.push(p)
      if @points.length > QuadTree.maxPointsPerLeaf
        @leaf = false
        newEdge = @edgeDist / 2
        MM = new QuadTree(@x - newEdge, @y - newEdge, newEdge)
        MP = new QuadTree(@x - newEdge, @y + newEdge, newEdge)
        PM = new QuadTree(@x + newEdge, @y - newEdge, newEdge)
        PP = new QuadTree(@x + newEdge, @y + newEdge, newEdge)
        @children = [MM, MP, PM, PP]
        @addPoint p_ for p_ in @points
        delete @points
    else
      idx = 2 * (p.position.x > @x) + (p.position.y > @y)
      # 0 -> MM, 1 -> MP, 2 -> PM, 3 -> PP
      @children[idx].addPoint(p)

  deletePoint: (p) ->
    if @leaf
      if p 




        