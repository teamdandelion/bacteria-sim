# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/

class Blob
  @numBlobs
  constructor: (@position, @genes, @energy, @environment) -> 
    @id = Blob.numBlobs++
    @photo  = @genes.photo
    @attack = @genes.attack
    @speed  = @genes.speed
    @efficency  = @genes.efficiency
    @energyPerSecond = @calcEnergyPerSecond()
    @attackPower = Math.pow(attack, 2)
    
  calcEnergyPerSecond: () ->
    speedBurn  = -@speed
    attackBurn = -@attack
    efficiencyFactor = 1 - @efficiency / 100
    @photo + (speedBurn + attackBurn) * efficiencyFactor    

  step: (observables, attackables) ->
    """One full step of simulation for this blob."""
    @energy += @energyPerSecond

    for a in attackables
      @energy += Math.min(@attackPower, a.energy)
      a.energy -= @attackPower

    if @energy < 0
      @die()
      return

    pursuitVals = (@calcPursuit o for o in observables)
    flightVals  = (@calcFlight  o for o in observables)

    maxPursuit = Math.max pursuitVals...
    maxFlight  = Math.max flightVals...

    pursuitThreshold = @genes.calcPursuitThreshold energy
    flightThreshold  = @genes.calcFlightThreshold  energy
    reproductionThreshold = @genes.
  

  flee: (targets) ->


