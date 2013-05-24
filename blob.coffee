STARTING_HP = 1000

class Blob
  @numBlobs
  constructor: (@genes, @energy, @environment) -> 
    @id = Blob.numBlobs++
    @hp = STARTING_HP
    @photo  = @genes.photo
    @attack = @genes.attack
    @speed  = @genes.speed
    @efficency  = @genes.efficiency
    @bodyEnergy = @


  @