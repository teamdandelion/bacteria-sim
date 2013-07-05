class C
  # Environment variables
  @X_MARGIN = 100
  @Y_MARGIN = 100
  # these stop blobs from flickering at margins, although at the expense of
  # computing 100 pixels in each direction of spcae that isnt displayed
  # if drawing code is improved to handle wraparounds elegantly then this will
  # be unnecessary. its a hack.
  @DISPLAY_X = window.innerWidth  - 20 ? 1000
  @DISPLAY_Y = window.innerHeight - 20 ? 500

  @X_BOUND = @DISPLAY_X + 2 * @X_MARGIN
  @Y_BOUND = @DISPLAY_Y + 2 * @Y_MARGIN
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = off # change display bound if you turn this on

  @SMALL_SIZE  = 10
  @MEDIUM_SIZE = 30
  @LARGE_SIZE  = 60
  @HUGE_SIZE   = 200
  
  @TWO_TRADEOFF = off
  @HARSH_REPRODUCTION = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 20
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 400
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100

  @REPR_ENERGY_COST    = 700
  @MOVEMENT_SPEED_FACTOR = .05
  @PHO_EPS =  .1
  @PHO_SQ_EPS = .06
  @ATK_EPS = -.5
  @ATK_SQ_EPS = 0
  @SPD_EPS = 0
  @AGE_ENERGY_DECAY = .001
  @RADIUS_FACTOR = .2
  @RADIUS_CONSTANT = 3 
  @BLOB_SIZE = 1.0 # single scaling factor
  @ENERGY_DECAY = .005
  @REPR_TIME_REQUIREMENT = 7

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 30
  @MOVE_UPDATE_AMT = 5
randomSign = () ->
  if Math.random() > .5 
    1
  else
    -1

maxByIndex = (arrayOfArrays, index) ->
  """Get the maximum Array in an Array of Arrays according to 
  ordering by one of the indexes
  e.g. maxByElem [["hello", 1], ["goodbye", 2]], 1 -> ["goodbye", 2]"""
  unless arrayOfArrays.length then return null
  maxIndex = arrayOfArrays[0][index]
  maxArray = arrayOfArrays[0]
  for arr in arrayOfArrays
    if arr[index] > maxIndex
      maxIndex = arr[index]
      maxArray = arr
  unless maxIndex? then throw new Error("maxByIndex: Index out of bounds for entire array")
  maxArray

minByIndex = (arrayOfArrays, index) ->
  """Get the minimum Array in an Array of Arrays according to 
  ordering by one of the indexes
  e.g. minByElem [["hello", 1], ["goodbye", 2]], 1 -> ["goodbye", 2]"""
  unless arrayOfArrays.length then return null
  minIndex = arrayOfArrays[0][index]
  minArray = arrayOfArrays[0]
  for arr in arrayOfArrays
    if arr[index] < minIndex
      minIndex = arr[index]
      minArray = arr
  unless minIndex? then throw new Error("minByIndex: Index out of bounds for entire array")
  minArray
# Vector class modified from work by Daniel Shiffman
# http://processingjs.org/learning/topic/flocking/
Math.PI2 = 2 * Math.PI

class Vector2D
    # Class methods for nondestructively operating
    for name in ['add', 'subtract', 'multiply', 'divide']
      do (name) ->
        Vector2D[name] = (a,b) ->
          a.copy()[name](b)

    Vector2D.randomUnitVector = () ->
      v = new Vector2D(Math.random()-.5, Math.random()-.5)
      v.normalize()

    Vector2D.randomVector = (xMax, yMax) ->
      new Vector2D(Math.random() * xMax, Math.random() * yMax)

    Vector2D.randomBoundedVector = (xMin, xMax, yMin, yMax) -> 
      v = Vector2D.randomVector(xMax-xMin, yMax-yMin)
      v.add(new Vector2D(xMin, yMin))

    Vector2D.randomHeading = () -> 
      Math.random() * Math.PI2

    Vector2D.negateHeading = (h) -> 
      (h + Math.PI) % Math.PI2

    Vector2D.headingVector = (h) -> 
      new Vector2D(Math.cos(h), Math.sin(h))

    constructor: (x=0,y=0) ->
      [@x,@y] = [x,y]

    copy: ->
      new Vector2D(@x,@y)

    magnitude: ->
      Math.sqrt(@x*@x + @y*@y)
    
    normalize: ->
      m = this.magnitude()
      this.divide(m) if m > 0
      return this
    
    limit: (max) ->
      if this.magnitude() > max
        this.normalize()
        return this.multiply(max)
      else
        return this
  
    heading: ->
      (Math.atan2(@y,@x) + Math.PI2) % Math.PI2

    eucl_distance: (other) ->
      dx = @x-other.x
      dy = @y-other.y
      Math.sqrt(dx*dx + dy*dy)

    distSq: (other) -> 
      dx = @x - other.x
      dy = @y - other.y
      dx*dx + dy*dy

    distance: (other, dimensions = false) ->
      dx = Math.abs(@x-other.x)
      dy = Math.abs(@y-other.y)
      # Wrap
      if dimensions
        dx = if dx < dimensions.width/2 then dx else dimensions.width - dx
        dy = if dy < dimensions.height/2 then dy else dimensions.height - dy

      Math.sqrt(dx*dx + dy*dy)

    subtract: (other) ->
      @x -= other.x
      @y -= other.y
      this
 
    add: (other) ->
      @x += other.x
      @y += other.y
      this

    divide: (n) ->
      [@x,@y] = [@x/n,@y/n]
      this

    multiply: (n) ->
      [@x,@y] = [@x*n,@y*n]
      this
    
    dot: (other) ->
      @x*other.x + @y*other.y
    
    # Not the strict projection, the other isn't converted to a unit vector first.
    projectOnto: (other) ->
      other.copy().multiply(this.dot(other))
    
    wrapToBound: (xBound, yBound) -> 
      @x = (@x+xBound) % xBound
      @y = (@y+yBound) % yBound

    # Called on a vector acting as a position vector to return the wrapped representation closest
    # to another location
    wrapRelativeTo: (location, dimensions) ->
      v = this.copy()
      for a,key of {x:"width", y:"height"}
        d = this[a]-location[a]
        map_d = dimensions[key]
        # If the distance is greater than half the map wrap it.
        if Math.abs(d) > map_d/2
          # If the distance is positive, then the this vector is in front of the location, and it 
          # would be closer to the location if it were wrapped to the negative behind the axis
          if d > 0
            # Take the distance to the axis and put the point behind the opposite side of the map by
            # that much
            v[a] = (map_d - this[a]) * -1
          else
          # If the distance is negative, then this this vector is behind the location, and it
          # would be closer if it were wrapped in front of the location past the axis in the positive
          # direction. Take the distance back to the axis, and put the point past the edge by that much
            v[a] = (this[a] + map_d)
      v

    invalid: () ->
      return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y)
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

    
ALWAYS_REPRODUCE = off

class GeneCode
  """The genes for a particular blob. This determines the stats and
  AI for the blob. The stats are Attack, Speed, Photosynthesis, and 
  efficiency. The AI is structured as a neural net with the gene's 
  energy level and nearby observable objects as inputs, and with 
  pursue(object), flee(object), reproduce() as output nodes.
  The blob will take the action with the signal that most exceeds
  its threshold, or no action if no signals exceed threshold"""
  @copy = (genecode) -> 
    newGenes = {}
    for key, oldGene of genecode.genes
      newGenes[key] = Gene.copy(oldGene)
    new GeneCode(newGenes)

  constructor: (@genes) ->
    @genes ?= 
      # determines the stats
      atk: new Gene(null, 0, 100)
      spd: new Gene(null, 0, 100)
      pho: new Gene(null, 0, 100)
      eff: new Gene(null, 0, 100)

      # determines the nucleus color
      red: new Gene(null, 0, 255, 1)
      grn: new Gene(null, 0, 255, 1)
      blu: new Gene(null, 0, 255, 1)
      # decision threhsolds are calculated as base + modifier * energy
      huntBase: new Gene(null, -10000, 10000, 100)
      fleeBase: new Gene(null, -10000, 10000, 100)
      reprBase: new Gene(null, -10000, 10000, 100)
      huntMod:  new Gene()
      fleeMod:  new Gene()
      reprMod:  new Gene(null, 0)
      
      # mapping from other blob's stats to this blob's hunt response
      nrgHunt: new Gene()
      atkHunt: new Gene()
      spdHunt: new Gene()
      phoHunt: new Gene()
      effHunt: new Gene()
      dstHunt: new Gene()
      clrHunt: new Gene()


      # mapping from other blob's stats to this blob's flee response
      nrgFlee: new Gene()
      atkFlee: new Gene()
      spdFlee: new Gene()
      phoFlee: new Gene()
      effFlee: new Gene()
      dstFlee: new Gene()
      clrFlee: new Gene()

      childEnergy: new Gene(null, 0, 1000, 1)

    if C.TWO_TRADEOFF
      atk_pho_total = @genes.atk.val + @genes.pho.val 
      spd_eff_total = @genes.spd.val + @genes.eff.val
    else
      atk_pho_total = @genes.atk.val + @genes.pho.val + @genes.spd.val + @genes.eff.val
      spd_eff_total = atk_pho_total
    @atk = @genes.atk.val / atk_pho_total * 100
    @pho = @genes.pho.val / atk_pho_total * 100
    @spd = @genes.spd.val / spd_eff_total * 100
    @eff = @genes.eff.val / spd_eff_total * 100

    @red = @genes.red.val
    @grn = @genes.grn.val
    @blu = @genes.blu.val



  chooseAction: (energy, observables) ->
    # an observable is a [blob, distance] pair

    if ALWAYS_REPRODUCE
      return {"type": "repr", "argument": 0}
    huntPairs = ([@calcHuntImpulse(o), o] for o in observables)
    fleePairs = ([@calcFleeImpulse(o), o] for o in observables)

    maxHunt = maxByIndex(huntPairs, 0) ? [0, null]
    maxFlee = maxByIndex(fleePairs, 0) ? [0, null]

    huntThreshold = @genes.huntBase.val + @genes.huntMod.val * energy
    fleeThreshold = @genes.fleeBase.val + @genes.fleeMod.val * energy
    reprThreshold = @genes.reprBase.val + @genes.reprMod.val * energy
    
    huntSignal = @genes.huntMod.val * energy + @genes.huntBase.val + maxHunt[0]
    fleeSignal = @genes.fleeMod.val * energy + @genes.fleeBase.val + maxFlee[0]
    reprSignal = @genes.reprMod.val * energy + @genes.reprBase.val   

    fleeAction = [fleeSignal, 'flee', maxFlee[1]]
    huntAction = [huntSignal, 'hunt', maxHunt[1]]
    reprAction = [reprSignal, 'repr', @genes.childEnergy.val]

    actions = [huntAction, fleeAction, reprAction]
    maxAction = maxByIndex(actions, 0)

    action = {"type": null}
    if maxAction[0] > 0
      action.type     = maxAction[1]
      action.argument = maxAction[2]
    action

  calcColorDist: (b) -> 
    # high value indicates high distance
    # negative value indicates closeness
    dred = Math.abs(b.red - @red)
    dgrn = Math.abs(b.grn - @grn)
    dblu = Math.abs(b.blu - @blu)
    dred + dgrn + dblu - 10


  calcHuntImpulse: ([b, dist]) -> 
    i =  @genes.nrgHunt.val * b.energy
    i += @genes.atkHunt.val * (b.atk - @atk)
    i += @genes.spdHunt.val * (b.spd - @spd)
    i += @genes.phoHunt.val * b.pho
    i += @genes.effHunt.val * b.eff
    i += @genes.dstHunt.val * dist
    i += @genes.clrHunt.val * @calcColorDist(b)
  
  calcFleeImpulse: ([b, dist]) -> 
    i =  @genes.nrgFlee.val * b.energy
    i += @genes.atkFlee.val * (b.atk - @atk)
    i += @genes.spdFlee.val * (b.spd - @atk)
    i += @genes.phoFlee.val * b.pho
    i += @genes.effFlee.val * b.eff
    i += @genes.dstFlee.val * dist
    i += @genes.clrFlee.val * @calcColorDist(b)

class Gene
  """Represent a single gene in the GeneCode. Has method for mutation.
  In future, plan to change so it references GeneCode and gets mutability
  info from GeneCode. Could be made more efficient by having GeneCodes with
  the same Gene share references to the object."""
  Gene.copy = (old) -> 
    newGene = new Gene(old.val, old.min, old.max, old.mutationSize)
    newGene.mutate()

  constructor: (@val, @min=-100, @max=100, @mutationSize=5) ->
    @val ?= Math.random() * (@max-@min) + @min
    @mutationProbability = C.MUTATION_PROBABILITY

  mutate: () ->
    if Math.random() < @mutationProbability
      sign = randomSign()
      mutationSize = @mutationSize * 2 * Math.random() * C.MUTATION_CONSTANT
      @val += sign * mutationSize
      @val = Math.max @val, @min
      @val = Math.min @val, @max
    this
class Blob
  constructor: (@simulation, @id, @energy=0, @geneCode) -> 
    @age = 0
    @id += '' #coerce to string to avoid equality issues
    @geneCode ?= new GeneCode()
    @pho = @geneCode.pho
    @atk = @geneCode.atk
    @spd = @geneCode.spd
    @eff = @geneCode.eff

    #nucleus colors
    @red = @geneCode.red
    @grn = @geneCode.grn
    @blu = @geneCode.blu

    @currentHeading = null
    @maxMovement = @spd * C.MOVEMENT_SPEED_FACTOR
    @stepsUntilNextAction = 0 
    @stepsUntilNextQuery = 0
    @alive = on
    @neighborDists = {}
    @calculateEnergyAndRadius()

  calculateEnergyAndRadius: () ->
    @efficiencyFactor = 1 - (@eff / 100) * .75
    @energyPerSecond  =  @pho * (@pho * C.PHO_SQ_EPS + C.PHO_EPS)
    @energyPerSecond += (@atk * (@atk * C.ATK_SQ_EPS + C.ATK_EPS)) * @efficiencyFactor
    @energyPerSecond += @spd * C.SPD_EPS * @efficiencyFactor
    @energyPerSecond -= C.AGE_ENERGY_DECAY * @age
    @attackPower = @atk*@atk
    @calculateRadius()

  calculateRadius: () ->
    @rad = Math.sqrt(@energy) * C.RADIUS_FACTOR + C.RADIUS_CONSTANT
    @rad *= C.BLOB_SIZE


  preStep: () ->
    """One full step of simulation for this blob.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the simulation"""
    @attackedThisTurn = {}
    @attackEnergyThisTurn = 0
    @numAttacks = 0
    @movedLastTurn = @movedThisTurn
    @movedThisTurn = 0

    @energy += @energyPerSecond
    @age++
    @energy *= (1-C.ENERGY_DECAY)
    """Neighbors: Everything within seeing distance. Represented as
    list of blobs. Querying only once every 10 steps, so force-recalc
    distance for each neighbor everytime."""
    if @stepsUntilNextQuery <= 0
      @neighbors = @simulation.getNeighbors(@id) 
      @stepsUntilNextQuery = 10
    else
      @neighbors = (n for n in @neighbors when n.alive)
      @stepsUntilNextQuery--
    # Return list of blobs
    
  getObservables: () ->
    for n in @neighbors
      if @neighborDists[n.id]?
        [dist, move_so_far] = @neighborDists[n.id]
        move_so_far += @movedLastTurn + n.movedLastTurn
        if move_so_far > C.MOVE_UPDATE_AMT
          delete @neighborDists[n.id]

      @neighborDists[n.id] ?= [@simulation.blobDist(@,n), 0]

    ([n, @neighborDists[n.id][0]] for n in @neighbors)

  chooseAction: () -> 
    if @maintainCurrentAction > 0
      if @action.type == "hunt" and not @simulation.isAlive(@huntTarget.id)
        #when a target dies, stop hunting it and do something else
        @maintainCurrentAction = 0
      else
        @maintainCurrentAction--
        return

    @action = @geneCode.chooseAction(@energy, @getObservables())
    if @action.type == "hunt"
      if @huntTarget
        @huntTarget = @action.argument[0]
        @maintainCurrentAction = 20 # keep hunting same target for 20 turns
    if @action.type == "repr"
      @maintainCurrentAction = C.REPR_TIME_REQUIREMENT
      @reproducing = on

    # reproduction maintenance is handled in reproduction code
    # -1 signals to repr code to check viability and put timeline if viable
    # this is so that if a cell 

  handleMovement: () ->
    if @action.type is "hunt"
      if @action.argument?
        # Let's set heading as the vector pointing towards target 
        [targetBlob, distance] = @action.argument 
        heading = @simulation.getHeading(@id, targetBlob.id)
        moveAmt = distance - 3 #will be further constrained by avail. energy and speed
        @wandering = null
      else
        # If we don't have a current heading, set it randomly
        # This way hunters move randomly but with determination when 
        # looking for prey
        # Conversely if they just lost sight of their prey they will
        # keep in the same direction
        @wandering ?= Vector2D.randomHeading()
        heading = @wandering
        moveAmt = @maxMovement

    else if @action.type is "flee" and @action.argument?
      [targetBlob, distance] = @action.argument 
      heading = @simulation.getHeading(@id, targetBlob.id)
      heading = Vector2D.negateHeading(heading)
      moveAmt = @maxMovement
      @wandering = null
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @wandering = null

    if heading? and moveAmt?
      @move(heading, moveAmt)

  handleAttacks: () ->
    for [aBlob, dist] in @getObservables()
      if dist < @rad + aBlob.rad + 1
        attackDelta = @attackPower - aBlob.attackPower
        if attackDelta >= 0
          # @attackedThisTurn[aBlob.id] = on
          @numAttacks++
          aBlob.numAttacks++
          # I attack them
          amt = Math.min(attackDelta, aBlob.energy)
          # if @observed? or aBlob.observed? 
            # console.log "#{@id} attacking #{aBlob.id} for #{amt}"

          @energy += amt
          @attackEnergyThisTurn += amt
          aBlob.energy -= attackDelta + 5
          aBlob.attackEnergyThisTurn -= attackDelta + 5
    if isNaN(@attackEnergyThisTurn)
      console.log @
      console.log "NAN attack energy"

  wrapUp: (@pos) -> 
    # hack: pass in position as an attribute so we can draw conveniently
    if @action.type is "repr"
      if @maintainCurrentAction == 0
        @reproduce(@action.argument)
        @reproducing = null

    @calculateEnergyAndRadius()
    #duplicated in constructor
    if @energy < 0 or isNaN(@energy)
      @simulation.removeBlob(@id)
      @alive = off


  move: (heading, moveAmt) ->
    moveAmt = Math.min(moveAmt, @maxMovement, @energy * C.MOVEMENT_PER_ENERGY / @efficiencyFactor)
    moveAmt = Math.max(moveAmt, 0) # in case @energy is negative due to recieved attacks
    @energy -= moveAmt * @efficiencyFactor / C.MOVEMENT_PER_ENERGY
    @simulation.moveBlob(@id, heading, moveAmt)
    @neighborDists = {}
    @movedThisTurn = moveAmt

  reproduce: (childEnergy) ->
    if @energy <= C.REPR_ENERGY_COST
      if C.HARSH_REPRODUCTION then @energy -= C.REPR_ENERGY_COST / 2 
      return
    if childEnergy > (@energy-C.REPR_ENERGY_COST)/2
      if C.HARSH_REPRODUCTION then @energy -= C.REPR_ENERGY_COST / 2
      return
    if @energy >= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      @energy  -= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      childGenes = GeneCode.copy(@geneCode)
      @simulation.addChildBlob(@id, childEnergy, childGenes)
class Simulation
  constructor: (starting_blobs=20) ->
    @blobs = {}
    @qtree = new QuadTree(C.X_BOUND, C.Y_BOUND, C.QTREE_BUCKET_SIZE)
    @location = @qtree.id2point
    @nBlobs = 0
    @nextBlobId = 0
    @observedBlobID = null
    for i in [0...starting_blobs]
      @addRandomBlob()

  observeBlob: (xCoord, yCoord) -> 
    console.log "Called observeBlob with " + xCoord + "," + yCoord
    clickLocation = new Vector2D(xCoord, yCoord)
    # find closest blob to the click
    if @observedBlob?
      prevId = @observedBlob.id
      @observedBlob.observed = null
      @observedBlob = null
    nearbyBlobs = @getAdjacent(clickLocation, 80)
    nearbyBlobs = ([b, clickLocation.distSq(@location[b.id])] for b in nearbyBlobs)
    selected = minByIndex(nearbyBlobs, 1)
    if selected? and selected[1] < selected[0].rad + 10 and selected[0].id != prevId
      selected = selected[0]
      @observedBlob = selected
      console.log "Observing blob:" + @observedBlob.id
      # console.log @observedBlob
      @observedBlob.observed = on

  step: () ->
    @qtree.rebuild()
    for id, blob of @blobs
      blob.preStep()
      blob.chooseAction()

    for id, blob of @blobs
      blob.handleMovement()

    for id, blob of @blobs
      blob.handleAttacks()

    for id, blob of @blobs
      blob.wrapUp(@location[id])

  getNeighbors: (blobID) ->
    pos = @location[blobID]
    rad = @blobs[blobID].rad
    @getAdjacent(pos, C.NEIGHBOR_DISTANCE + rad * 1.5, blobID)

  getAdjacent: (position, distance, blobID) ->
    # Returns nearby blobs
    queryResult = @qtree.approximateCircleQuery(position, distance)
    (@blobs[otherID] for otherID in queryResult when otherID != blobID)


  getHeading: (sourceID, targetID) ->
    sourcePos = @location[sourceID]
    targetPos = @location[targetID]
    Vector2D.subtract(targetPos, sourcePos).heading()

  moveBlob: (blobID, heading, moveAmt) -> 
    sourcePos = @location[blobID]
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

  addRandomBlob: () -> 
    pos = Vector2D.randomBoundedVector(C.X_MARGIN, C.DISPLAY_X + C.X_MARGIN,
                                       C.Y_MARGIN, C.DISPLAY_Y + C.Y_MARGIN)
    @addBlob(pos, C.STARTING_ENERGY)

  addChildBlob: (parentID, childEnergy, childGenes) -> 
    parentPosition = @location[parentID]
    parentRadius = @blobs[parentID].rad
    parentSpeed = @blobs[parentID].spd
    childOffset = Vector2D.randomUnitVector()
    childOffset.multiply(C.CHILD_DISTANCE + parentRadius + parentSpeed / 2)
    childPosition = childOffset.add(parentPosition)
    childPosition.wrapToBound(C.X_BOUND, C.Y_BOUND)
    @addBlob(childPosition, childEnergy, childGenes)

  removeBlob: (blobID) ->
    if @observedBlob? and @observedBlob.id == blobID
      @observedBlob = null
    delete @blobs[blobID]
    @qtree.removeObject(blobID)
    @nBlobs--

  killAllBlobs: () ->
    for blobID, blob of @blobs
      @removeBlob(blobID)

  isAlive: (blobID) -> 
    blobID of @blobs

  blobDistSq: (blob1, blob2) ->
    p1 = @location[blob1.id]
    p2 = @location[blob2.id]
    p1.distSq(p2)

  blobDist: (blob1, blob2) ->
    Math.sqrt @blobDistSq(blob1, blob2)

sim = new Simulation()
while true
  sim.step()
  postMessage sim.blobs

