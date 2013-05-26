# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/

class Blob
  @numBlobs = 0
  constructor: (@position, @genes, @energy, @environment) -> 
    @id = Blob.numBlobs++
    @age = 0
    @photo  = @genes.photo
    @attack = @genes.attack
    @speed  = @genes.speed
    @efficency  = @genes.efficiency
    @calcEnergyPerSecond()
    @attackPower = Math.pow(attack, 2)
    @currentHeading = null
    
  calcEnergyPerSecond: () ->
    speedBurn  = -@speed
    attackBurn = -@attack
    @efficiencyFactor = 1 - @efficiency / 100
    @energyPerSecond = @photo + (speedBurn + attackBurn) * @efficiencyFactor

  step: (observables, attackables) ->
    """One full step of simulation for this blob.
    Observables: Everything within seeing distance.
    Attackables: Everything which is adjacent and close enough to 
    auto-attack. These are passed by the environment"""
    @energy += @energyPerSecond
    @age++

    for a in attackables
      @energy += Math.min(@attackPower, a.energy)
      a.energy -= @attackPower

    action = @chooseAction(observables)
    if action.actionType is "repr"
      @reproduce(action)
    
    @calculateHeading(action)
    if @currentHeading?
      @move()

    if @energy < 0
      @environment.removeBlob(this)

  calculateHeading: (action) ->
    if action.actionType is "pursuit"
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

    else if action.actionType is "flight" and action.argument?
      target = action.argument
      @currentHeading = Vector2D.subtract(@position, target.position)
      @currentHeading.normalize()
      # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      @currentHeading = null

  chooseAction: (observables) ->
    pursuitPairs = ([@calcPursuit o, o] for o in observables)
    flightPairs  = ([@calcFlight  o, o] for o in observables)

    maxPursuit = maxByIndex pursuitPairs, 0 ? [0, null]
    maxFlight  = maxByIndex flightPairs,  0 ? [0, null]

    pursuitThreshold = @genes.calcPursuitThreshold energy
    flightThreshold  = @genes.calcFlightThreshold  energy
    
    pursuitSignal = [maxPursuit[0] - pursuitThreshold, 'pursuit', maxPursuit[1]]
    flightSignal  = [maxFlight[0]  - flightThreshold,  'flight' , maxFlight[1] ]
    reprSignal = [@genes.reprSignal energy, 'repr', @genes.childEnergy energy]

    signals = [pursuitSignal, flightSignal, reprSignal]
    maxSignal = maxByIndex 0, signals

    action = {"type": null}
    if maxSignal[0] > 0
      action.type = maxSignal[1]
      action.argument = maxSignal[2]

  reproduce: (action) ->
    childEnergy = action.childEnergy
    if @energy >= childEnergy + REPR_BASE_COST
      @energy  -= childEnergy + REPR_BASE_COST
      @environment.addChildBlob(this, childEnergy)

  move: (heading) ->
    if @energy > @speed * @efficiencyFactor
      @energy -= @speed * @efficiencyFactor
      movement = Vector2D.multiply(heading, @speed)
      @position.add(movement)

