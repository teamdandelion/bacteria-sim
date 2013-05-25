# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/

class Blob
  @numBlobs
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

    if @energy < 0
      @die()
      return
    action = @chooseAction(observables)
    @calculateHeading(action)
    if action.actionType is "reproduction"
      @reproduce(action)

  calculateHeading: (action) ->
    if action.actionType is "pursuit"
      if "pursuitTarget" of action
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

    else if action.actionType is "flight" and "flightTarget" of action
        @currentHeading = Vector2D.subtract(@position, target.position)
        @currentHeading.normalize()
        # Current implementation only flees 1 target w/ highest fear

    else # No action -> stay put
      currentHeading = null

  chooseAction: (observables) ->
    pursuitPairs = ([@calcPursuit o, o] for o in observables)
    flightPairs  = ([@calcFlight  o, o] for o in observables)

    maxPursuit = myMaximumFn pursuitPairs...
    maxFlight  = myMaximumFn flightPairs...

    pursuitThreshold = @genes.calcPursuitThreshold energy
    flightThreshold  = @genes.calcFlightThreshold  energy
    
    pursuitSignal = [maxPursuit[0] - pursuitThreshold, 'P']
    flightSignal  = [maxFlight[0]  - flightThreshold , 'F']
    reproductionSignal = [@genes.calcReproductionSignal energy

    signals = [pursuitSignal, 'P']

  reproduce: (action) ->
    childEnergy = action.childEnergy
    if @energy >= childEnergy + REPRODUCTION_BASE_COST
      @energy -= childEnergy + REPRODUCTION_BASE_COST
      @environment.addChildBlob(this, childEnergy)

  flee: (targets) ->


