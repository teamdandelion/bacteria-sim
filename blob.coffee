class Blob
  constructor: (@environment, @id, @energy=0, @geneCode) -> 
    @age = 0
    @id += '' #coerce to string to avoid equality issues
    @geneCode ?= new GeneCode()
    @pho = @geneCode.pho
    @atk = @geneCode.atk
    @spd = @geneCode.spd
    @eff = @geneCode.eff
    @efficiencyFactor = 1 - @eff / 100
    @energyPerSecond  = @pho * C.PHO_EPS
    @energyPerSecond += @atk * C.ATK_EPS * @efficiencyFactor
    @energyPerSecond += @spd * C.SPD_EPS * @efficiencyFactor
    @attackPower = @atk*3
    @currentHeading = null
    @maxMovement = @spd * C.MOVEMENT_SPEED_FACTOR
    @rad = Math.sqrt(@energy) * C.RADIUS_FACTOR + C.RADIUS_CONSTANT # Duplicated in wrap-up

  preStep: () ->
    """One full step of simulation for this blob.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the environment"""
    @attackedThisTurn = {}
    @attackEnergyThisTurn = 0
    @numAttacks = 0

    @energy += @energyPerSecond
    @age++
    @energyPerSecond -= C.AGE_ENERGY_DECAY
    # @energy *= (1-C.ENERGY_DECAY)
    

  chooseAction: () -> 
    """Neighbors: Everything within seeing distance. Represented as
    list of [blob, distance] pairs."""
    neighbors = @environment.getNeighbors(@id) 
    # Return list of [Blob, Distance]

    @action = @geneCode.chooseAction(@energy, neighbors)

  handleMovement: () ->
    if @action.type is "hunt"
      if @action.argument?
        # Let's set heading as the vector pointing towards target 
        [targetBlob, distance] = @action.argument 
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

    else if @action.type is "flee" and @action.argument?
      [targetBlob, distance] = @action.argument 
      heading = @environment.getHeading(@id, targetBlob.id)
      heading = Vector2D.negateHeading(heading)
      moveAmt = @maxMovement
      @wandering = null
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @wandering = null

    if heading? and moveAmt?
      @move(heading, moveAmt)

  handleAttacks: () ->
    for [aBlob, dist] in @environment.getAttackables(@id)
      if dist < @.rad + aBlob.rad + 5 and aBlob.id not of @attackedThisTurn
        if aBlob.id == @id
          console.log "DETECTED ERROR ON BLOB " + @id
          console.log "getAttackables gave this: " + @environment.getAttackables(@id)
          console.log "MY ID, THEIR ID:" + @id, aBlob.id
          throw new Error("Attacking self!")
        @attackedThisTurn[aBlob.id] = on
        @numAttacks++
        attackDelta = @attackPower - aBlob.attackPower
        if attackDelta > 0
          # I attack them
          amt = Math.min(attackDelta, aBlob.energy)
          @energy += amt
          @attackEnergyThisTurn += amt
          aBlob.energy -= attackDelta + 5
          aBlob.attackEnergyThisTurn -= attackDelta + 5
        else
          # They attack me!
          @energy -= attackDelta + 5
          @attackEnergyThisTurn -= attackDelta + 5
          amt = Math.min(attackDelta, @energy)
          aBlob.energy += amt
          aBlob.attackEnergyThisTurn += amt


  wrapUp: () -> 
    if @action.type is "repr"
      @reproduce(@action.argument)

    @rad = Math.sqrt(@energy) * C.RADIUS_FACTOR + C.RADIUS_CONSTANT # Radius of the blob
    #duplicated in constructor
    if @energy < 0
      @environment.removeBlob(@id)


  move: (heading, moveAmt) ->
    moveAmt = Math.min(moveAmt, @maxMovement, @energy * C.MOVEMENT_PER_ENERGY / @efficiencyFactor)
    moveAmt = Math.max(moveAmt, 0) # in case @energy is negative due to recieved attacks
    @energy -= moveAmt * @efficiencyFactor / C.MOVEMENT_PER_ENERGY
    @environment.moveBlob(@id, heading, moveAmt)

  reproduce: (childEnergy) ->
    if childEnergy > (@energy-C.REPR_ENERGY_COST)/2
      childEnergy = (@energy-C.REPR_ENERGY_COST)/2
    if @energy >= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      @energy  -= childEnergy + C.REPR_ENERGY_COST * @efficiencyFactor
      childGenes = GeneCode.copy(@geneCode)
      @environment.addChildBlob(@id, childEnergy, childGenes)
