class Blob
  constructor: (@environment, @id, @energy=0, @geneCode) -> 
    @age = 0
    @geneCode ?= new GeneCode()
    @pho = @geneCode.pho
    @atk = @geneCode.atk
    @spd = @geneCode.spd
    @eff = @geneCode.eff
    @efficiencyFactor = 1 - @eff / 100
    @energyPerSecond  = @pho * C.PHO_EPS
    @energyPerSecond += @atk * C.ATK_EPS * @efficiencyFactor
    @energyPerSecond += @spd * C.SPD_EPS * @efficiencyFactor
    @attackPower = Math.pow(@atk, 2)
    @currentHeading = null
    @maxMovement = @spd * C.MOVEMENT_SPEED_FACTOR
    
  step: () ->
    """One full step of simulation for this blob.
    Observables: Everything within seeing distance. Represented as
    list of [blob, distance] pairs.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the environment"""
    @energy += @energyPerSecond
    @age++
    @energyPerSecond -= C.AGE_ENERGY_DECAY

    neighbors = @environment.getNeighbors(@id) 
    # Return list of [Blob, Distance]

    action = @geneCode.chooseAction(@energy, neighbors)
    if action.type is "repr"
      @reproduce(action.argument)
    
    @handleMovement(action)

    for [attackableBlob, _] in @environment.getAttackables(@id)
      @energy += Math.min(@attackPower, attackableBlob.energy)
      attackableBlob.energy -= @attackPower
    
    if @energy < 0
      @environment.removeBlob(@id)


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
        moveAmt = @maxMovement

    else if action.type is "flight" and action.argument?
      [targetBlob, distance] = action.argument 
      heading = @environment.getHeading(@id, targetBlob.id)
      heading = Vector2D.negateHeading(heading)
      moveAmt = @maxMovement
      @wandering = null
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @wandering = null

    if heading? and moveAmt?
      @move(heading, moveAmt)

  move: (heading, moveAmt) ->
    moveAmt = Math.min(moveAmt, @maxMovement, @energy * C.MOVEMENT_PER_ENERGY / @efficiencyFactor)
    moveAmt = Math.max(moveAmt, 0) # in case @energy is negative due to recieved attacks
    @energy -= moveAmt * efficiencyFactor / C.MOVEMENT_PER_ENERGY
    @environment.moveBlob(@id, heading, moveAmt)

  reproduce: (childEnergy) ->
    if @energy >= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      @energy  -= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      childGenes = GeneCode.copy(@geneCode)
      @environment.addChildBlob(@id, childEnergy, childGenes)
