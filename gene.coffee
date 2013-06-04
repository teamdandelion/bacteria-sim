ALWAYS_REPRODUCE = off

class GeneCode
  """The genes for a particular blob. This determines the stats and
  AI for the blob. The stats are Attack, Speed, Photosynthesis, and 
  efficiency. The AI is structured as a neural net with the gene's 
  energy level and nearby observable objects as inputs, and with 
  pursue(object), flee(object), reproduce() as output nodes.
  The blob will take the action with the signal that most exceeds
  its threshold, or no action if no signals exceed threshold"""
  @copy = (genecode) -> 
    newGenes = {}
    for key, oldGene of genecode.genes
      newGenes[key] = Gene.copy(oldGene)
    new GeneCode(newGenes)

  constructor: (@genes) ->
    @genes ?= 
      # determines the stats
      atk: new Gene(null, 0, 100)
      spd: new Gene(null, 0, 100)
      pho: new Gene(null, 0, 100)
      eff: new Gene(null, 0, 100)
      # decision threhsolds are calculated as base + modifier * energy
      huntBase: new Gene()
      fleeBase: new Gene()
      reprBase: new Gene()
      huntMod:  new Gene()
      fleeMod:  new Gene()
      reprMod:  new Gene()
      
      # mapping from other blob's stats to this blob's hunt response
      nrgHunt: new Gene()
      atkHunt: new Gene()
      spdHunt: new Gene()
      phoHunt: new Gene()
      effHunt: new Gene()
      dstHunt: new Gene()

      # mapping from other blob's stats to this blob's flee response
      nrgFlee: new Gene()
      atkFlee: new Gene()
      spdFlee: new Gene()
      phoFlee: new Gene()
      effFlee: new Gene()
      dstFlee: new Gene()

      childEnergy: new Gene(null, 0, 1000, 1)

    total_Stats = @genes.atk.val + @genes.spd.val + @genes.pho.val + @genes.eff.val
    @atk = @genes.atk.val / total_Stats * 100
    @spd = @genes.spd.val / total_Stats * 100
    @pho = @genes.pho.val / total_Stats * 100
    @eff = @genes.eff.val / total_Stats * 100

  chooseAction: (energy, observables) ->
    # an observable is a [blob, distance] pair

    if ALWAYS_REPRODUCE
      return {"type": "repr", "argument": 0}
    huntPairs = ([@calcHuntImpulse(o), o[0]] for o in observables)
    fleePairs = ([@calcFleeImpulse(o), o[0]] for o in observables)

    maxHunt = maxByIndex(huntPairs, 0) ? [0, null]
    maxFlee = maxByIndex(fleePairs, 0) ? [0, null]

    huntThreshold = @genes.huntBase.val + @genes.huntMod.val * energy
    fleeThreshold = @genes.fleeBase.val + @genes.fleeMod.val * energy
    reprThreshold = @genes.reprBase.val + @genes.reprMod.val * energy
    
    huntSignal = @genes.huntMod.val * energy + @genes.huntBase.val + maxHunt[0]
    fleeSignal = @genes.fleeMod.val * energy + @genes.fleeBase.val + maxFlee[0]
    reprSignal = @genes.reprMod.val * energy + @genes.reprBase.val   

    fleeAction = [fleeSignal, 'flee', maxFlee[1]]
    huntAction = [huntSignal, 'hunt', maxHunt[1]]
    reprAction = [reprSignal, 'repr', @genes.childEnergy.val]

    actions = [huntAction, fleeAction, reprAction]
    maxAction = maxByIndex(actions, 0)

    action = {"type": null}
    if maxAction[0] > 0
      action.type     = maxAction[1]
      action.argument = maxAction[2]
    action

  calcHuntImpulse: ([b, dist]) -> 
    i =  @genes.nrgHunt.val * b.energy
    i += @genes.atkHunt.val * b.atk
    i += @genes.spdHunt.val * b.spd
    i += @genes.phoHunt.val * b.pho
    i += @genes.effHunt.val * b.eff
    i += @genes.dstHunt.val * dist
  
  calcFleeImpulse: ([b, dist]) -> 
    i =  @genes.nrgFlee.val * b.energy
    i += @genes.atkFlee.val * b.atk
    i += @genes.spdFlee.val * b.spd
    i += @genes.phoFlee.val * b.pho
    i += @genes.effFlee.val * b.eff
    i += @genes.dstFlee.val * dist

class Gene
  """Represent a single gene in the GeneCode. Has method for mutation.
  In future, plan to change so it references GeneCode and gets mutability
  info from GeneCode. Could be made more efficient by having GeneCodes with
  the same Gene share references to the object."""
  Gene.copy = (old) -> 
    newGene = new Gene(old.val, old.min, old.max, old.mutationSize)
    newGene.mutate()

  constructor: (@val, @min=-100, @max=100, @mutationSize=5) ->
    @val ?= Math.random() * (@max-@min) + @min
    @mutationProbability = .3

  mutate: () ->
    if Math.random() < @mutationProbability
      sign = randomSign()
      mutationSize = @mutationSize * 2 * Math.random()
      @val += sign * mutationSize
      @val = Math.max @val, @min
      @val = Math.min @val, @max
    this

randomSign = () ->
  if Math.random() > .5 
    1
  else
    -1

maxByIndex = (arrayOfArrays, index) ->
  """Get the maximum Array in an Array of Arrays according to 
  ordering by one of the indexes
  e.g. maxByElem [["hello", 1], ["goodbye", 2]], 1 -> ["goodbye", 2]"""
  unless arrayOfArrays.length then return null
  maxIndex = arrayOfArrays[0][index]
  maxArray = arrayOfArrays[0]
  for arr in arrayOfArrays
    if arr[index] > maxIndex
      maxIndex = arr[index]
      maxArray = arr
  unless maxIndex? then throw new Error("maxByIndex: Index out of bounds for entire array")
  maxArray


stdGenes =
  # determines the stats
  atk: new Gene(null, 0, 100, 1)
  spd: new Gene(null, 0, 100, 1)
  pho: new Gene(null, 0, 100, 1)
  eff: new Gene(null, 0, 100, 1)
  # decision threhsolds are calculated as base + modifier * energy
  huntBase: new Gene(-100)
  fleeBase: new Gene(-100)
  reprBase: new Gene(-400)
  huntMod:  new Gene(-10)
  fleeMod:  new Gene(5)
  reprMod:  new Gene(10)
  # mapping from other blob's stats to this blob's hunt response
  nrgHunt: new Gene(3)
  atkHunt: new Gene(-5)
  spdHunt: new Gene(-5)
  phoHunt: new Gene(5)
  effHunt: new Gene(5)
  dstHunt: new Gene(-3)
  # mapping from other blob's stats to this blob's flee response
  nrgFlee: new Gene(0)
  atkFlee: new Gene(10)
  spdFlee: new Gene(6)
  phoFlee: new Gene(-10)
  effFlee: new Gene(-5)
  dstFlee: new Gene(-5)
  childEnergy: new Gene(100)
stdGeneCode = new GeneCode(stdGenes)
