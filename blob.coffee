# Rendering code adopted from Harry Brundage's flocking example,
# adopted in turn from Daniel Shiffman's flocking example, found 
# here: http://processingjs.org/learning/topic/flocking/


class BlobRules
  @energyBurnRate =


class Blob
  @numBlobs
  constructor: (@position, @genes, @energy, @environment) -> 
    @id = Blob.numBlobs++
    @photo  = @genes.photo
    @attack = @genes.attack
    @speed  = @genes.speed
    @efficency  = @genes.efficiency
    @energyPerSecond = calcEnergyPerSecond()
    


  calcEnergyPerSecond: () ->
    speedBurn  = -@speed
    attackBurn = -Math.pow(@attack, 2)
    efficiencyFactor = 1 - @efficiency / 100
    @photo + (speedBurn + attackBurn) * efficiencyFactor    
