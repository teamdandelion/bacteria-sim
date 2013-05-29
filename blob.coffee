# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/

class Blob
  @numBlobs = 0
  # TODO: Change so that the environment sets the id
  constructor: (@environment, @position, @energy=0, @geneCode) -> 
    @id  = Blob.numBlobs++
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

    neighbors = @environment.calculateNeighbors(@)

    for [neighborBlob, distance] in neighbors
      # Note: Order in which blobs are considered can change outcome
      if distance < Cons.ATTACK_DISTANCE
        @energy += Math.min(@attackPower, neighborBlob.energy)
        neighborBlob.energy -= @attackPower

    action = @chooseAction(neighbors)
    if action.type is "repr"
      @reproduce(action.argument)
    
    @calculateHeading(action)
    if @currentHeading?
      @move(@currentHeading)

    if @energy < 0
      @environment.removeBlob(this)


  draw: (processing) ->
    processing.stroke(@atk*2.55,@pho*2.55,@spd*2.55)
    processing.strokeWeight(10)
    processing.point(@position.x, @position.y)


  calculateHeading: (action) ->
    if action.type is "pursuit"
      if action.argument?
        # Let's set heading as the vector pointing towards target 
        target = action.pursuitTarget
        @currentHeading = Vector2D.subtract(target.position, @position)
        @currentHeading.normalize()
      else
        # If we don't have a current heading, set it randomly
        # This way hunters move randomly but with determination when 
        # looking for prey
        # Conversely if they just lost sight of their prey they will
        # keep in the same direction
        @currentHeading ?= Vector2D.randomUnitVector()

    else if action.type is "flight" and action.argument?
      target = action.argument
      @currentHeading = Vector2D.subtract(@position, target.position)
      @currentHeading.normalize()
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @currentHeading = null

  chooseAction: (observables) ->
    @geneCode.calculateAction(@energy, observables)
    

  reproduce: (childEnergy) ->
    if @energy >= childEnergy + 50
      @energy  -= childEnergy + 50
      childGenes = GeneCode.copy(@geneCode)
      childOffset = Vector2D.randomUnitVector().multiply(Cons.CHILD_DISTANCE)
      childPosition = childOffset.add(@position)
      childBlob = new Blob(@environment, childPosition, childEnergy, childGenes)
      @environment.addBlob(childBlob)

  move: (heading) ->
    if @energy > @speed * @efficiencyFactor
      @energy -= @speed * @efficiencyFactor
      movement = Vector2D.multiply(heading, @speed)
      @position.add(movement)

  calcDistance: (otherBlob) ->
    @position.eucl_distance(otherBlob.position)

