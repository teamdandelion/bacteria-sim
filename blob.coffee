# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/

MOVEMENT_PER_ENERGY = 1
REPR_ENERGY_COST    = 100

class Blob
  constructor: (@environment, @id, @energy=0, @geneCode) -> 
    @age = 0
    @geneCode ?= new GeneCode()
    @pho = @geneCode.pho
    @atk = @geneCode.atk
    @spd = @geneCode.spd
    @eff = @geneCode.eff
    @efficiencyFactor = 1 - @eff / 100
    @energyPerSecond = @pho /5  - (@spd + @atk) * @efficiencyFactor
    @attackPower = Math.pow(@atk, 2)
    @currentHeading = null
    
  step: () ->
    """One full step of simulation for this blob.
    Observables: Everything within seeing distance. Represented as
    list of [blob, distance] pairs.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the environment"""
    @energy += @energyPerSecond
    @age++

    neighbors = @environment.getNeighbors(@) 
    # Return list of [Blob, Distance]

    action = @genecode.chooseAction(@energy, neighbors)
    if action.type is "repr"
      @reproduce(action.argument)
    
    @handleMovement(action)

    for attackableBlob in @environment.getAttackables(@)
      @energy += Math.min(@attackPower, attackableBlob.energy)
      attackableBlob.energy -= @attackPower
    
    if @energy < 0
      @environment.removeBlob(this)


  draw: (processing) ->
    processing.stroke(@atk*2.55,@pho*2.55,@spd*2.55)
    processing.strokeWeight(5)
    processing.point(@position.x, @position.y)


  handleMovement: (action) ->
    if action.type is "pursuit"
      if action.argument?
        # Let's set heading as the vector pointing towards target 
        [targetBlob, distance] = action.argument 
        heading = @environment.getHeading(@id, targetBlob.id)
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
        moveAmt = @speed

    else if action.type is "flight" and action.argument?
      [targetBlob, distance] = action.argument 
      heading = @environment.getHeading(@id, targetBlob.id)
      heading = Vector2D.negateHeading(heading)
      moveAmt = @speed
      @wandering = null
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @wandering = null

    if heading? and moveAmt?
      @move(heading, moveAmt)

  move: (heading, moveAmt) ->
    moveAmt = Math.min(moveAmt, @speed, @energy * MOVEMENT_PER_ENERGY / @efficiencyFactor)
    moveAmt = Math.max(moveAmt, 0) # in case @energy is negative due to recieved attacks
    @energy -= moveAmt * efficiencyFactor / MOVEMENT_PER_ENERGY
    @environment.moveBlob(@id, heading, moveAmt)

  reproduce: (childEnergy) ->
    if @energy >= childEnergy + REPR_ENERGY_COST * @efficiencyFactor
      @energy  -= childEnergy + REPR_ENERGY_COST * @efficiencyFactor
      childGenes = GeneCode.copy(@geneCode)
      @environment.addChildBlob(@id, childEnergy, childGenes)
