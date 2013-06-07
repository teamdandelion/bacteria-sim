class Blob
  constructor: (@environment, @id, @energy=0, @geneCode) -> 
    @age = 0
    @id += '' #coerce to string to avoid equality issues
    @geneCode ?= new GeneCode()
    #nucleus colors
    @red = @geneCode.red
    @grn = @geneCode.grn
    @blu = @geneCode.blu

    @redSq = @red*@red
    @grnSq = @grn*@grn
    @bluSq = @blu*@blu

    @currentHeading = null
    @stepsUntilNextAction = 0 
    @stepsUntilNextQuery = 0
    @alive = on
    @neighborDists = {}
    @calculateEnergyAndRadius()

  calculateEnergyAndRadius: () ->
    rEnergy = @environment.redEnergy * @redSq / @environment.total_red
    gEnergy = @environment.grnEnergy * @grnSq / @environment.total_grn
    bEnergy = @environment.bluEnergy * @bluSq / @environment.total_blu
    @energyPerSecond = rEnergy + gEnergy + bEnergy + C.BASE_EPS
    @calculateRadius()

  calculateRadius: () ->
    @rad = Math.sqrt(@energy) * C.RADIUS_FACTOR + C.RADIUS_CONSTANT
    @rad *= C.BLOB_SIZE


  preStep: () ->
    @calculateEnergyAndRadius()
    """One full step of simulation for this blob.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the environment"""
    @attackedThisTurn = {}
    @attackEnergyThisTurn = 0
    @numAttacks = 0
    @movedLastTurn = @movedThisTurn
    @movedThisTurn = 0

    console.log "A:" + @energy, @energyPerSecond
    @energy += @energyPerSecond
    @age++
    @energy *= (1-C.ENERGY_DECAY)
    """Neighbors: Everything within seeing distance. Represented as
    list of blobs. Querying only once every 10 steps, so force-recalc
    distance for each neighbor everytime."""
    if @stepsUntilNextQuery <= 0
      @neighbors = @environment.getNeighbors(@id) 
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

      @neighborDists[n.id] ?= [@environment.blobDist(@,n), 0]

    ([n, @neighborDists[n.id][0]] for n in @neighbors)

  chooseAction: () -> 
    if @maintainCurrentAction > 0
      if @action.type == "hunt" and not @environment.isAlive(@huntTarget.id)
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
        heading = @environment.getHeading(@id, targetBlob.id)
        moveAmt = distance #will be further constrained by avail. energy and speed
        @wandering = null
      else
        # If we don't have a current heading, set it randomly
        # This way hunters move randomly but with determination when 
        # looking for prey
        # Conversely if they just lost sight of their prey they will
        # keep in the same direction
        @wandering ?= Vector2D.randomHeading()
        heading = @wandering
        moveAmt = C.MOVE_SPEED

    else if @action.type is "flee" and @action.argument?
      [targetBlob, distance] = @action.argument 
      heading = @environment.getHeading(@id, targetBlob.id)
      heading = Vector2D.negateHeading(heading)
      moveAmt = C.MOVE_SPEED
      @wandering = null
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @wandering = null

    if heading? and moveAmt?
      @move(heading, moveAmt)

  handleAttacks: () ->
    for [aBlob, dist] in @getObservables()
      if dist < @rad + aBlob.rad + 1 and aBlob.id not of @attackedThisTurn
        @attackedThisTurn[aBlob.id] = on
        aBlob.attackedThisTurn[@id] = on

        redDelta = @red * aBlob.grn - aBlob.red * @grn
        grnDelta = @grn * aBlob.blu - aBlob.grn * @blu
        bluDelta = @blu * aBlob.red - aBlob.blu * @red
        attackDelta = redDelta + grnDelta + bluDelta
        attackDelta /= 30

        if attackDelta >= 0
          winner = @
          loser = aBlob
        else
          winner = aBlob
          loser = @
        @numAttacks++
        aBlob.numAttacks++
        amt = Math.min(attackDelta, loser.energy)
        loser.energy -= attackDelta
        winner.energy += amt
        loser.attackEnergyThisTurn -= attackDelta + C.CLUMP_PENALTY
        winner.attackEnergyThisTurn += amt - C.CLUMP_PENALTY

  wrapUp: () -> 
    if @action.type is "repr"
      if @maintainCurrentAction == 0
        @reproduce(@action.argument)
        @reproducing = null

    @calculateEnergyAndRadius()
    #duplicated in constructor
    if @energy < 0 or isNaN(@energy)
      if isNaN(@energy) 
        console.log "WARNING: Blob #{@id} had NaN energy"
      @environment.removeBlob(@id)
      @alive = off


  move: (heading, moveAmt) ->
    moveAmt = Math.min(moveAmt, C.MOVE_SPEED)
    @energy -= moveAmt / C.MOVEMENT_PER_ENERGY
    @environment.moveBlob(@id, heading, moveAmt)
    @neighborDists = {}
    @movedThisTurn = moveAmt

  reproduce: (childEnergy) ->
    if @energy <= C.REPR_ENERGY_COST
      if C.HARSH_REPRODUCTION then @energy -= C.REPR_ENERGY_COST / 2 
      return
    if childEnergy > (@energy-C.REPR_ENERGY_COST)/2
      if C.HARSH_REPRODUCTION then @energy -= C.REPR_ENERGY_COST / 2
      return
    if @energy >= childEnergy + C.REPR_ENERGY_COST
      @energy  -= childEnergy + C.REPR_ENERGY_COST
      childGenes = GeneCode.copy(@geneCode)
      @environment.addChildBlob(@id, childEnergy, childGenes)
