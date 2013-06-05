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

      # determines the nucleus color
      red: new Gene(null, 0, 255, 1)
      grn: new Gene(null, 0, 255, 1)
      blu: new Gene(null, 0, 255, 1)
      # decision threhsolds are calculated as base + modifier * energy
      huntBase: new Gene(null, -10000, 10000, 100)
      fleeBase: new Gene(null, -10000, 10000, 100)
      reprBase: new Gene(null, -10000, 10000, 100)
      huntMod:  new Gene()
      fleeMod:  new Gene()
      reprMod:  new Gene(null, 0)
      
      # mapping from other blob's stats to this blob's hunt response
      nrgHunt: new Gene()
      atkHunt: new Gene()
      spdHunt: new Gene()
      phoHunt: new Gene()
      effHunt: new Gene()
      dstHunt: new Gene()
      clrHunt: new Gene()


      # mapping from other blob's stats to this blob's flee response
      nrgFlee: new Gene()
      atkFlee: new Gene()
      spdFlee: new Gene()
      phoFlee: new Gene()
      effFlee: new Gene()
      dstFlee: new Gene()
      clrFlee: new Gene()

      childEnergy: new Gene(null, 0, 1000, 1)

    if C.TWO_TRADEOFF
      atk_pho_total = @genes.atk.val + @genes.pho.val 
      spd_eff_total = @genes.spd.val + @genes.eff.val
    else
      atk_pho_total = @genes.atk.val + @genes.pho.val + @genes.spd.val + @genes.eff.val
      spd_eff_total = atk_pho_total
    @atk = @genes.atk.val / atk_pho_total * 100
    @pho = @genes.pho.val / atk_pho_total * 100
    @spd = @genes.spd.val / spd_eff_total * 100
    @eff = @genes.eff.val / spd_eff_total * 100

    @red = @genes.red.val
    @grn = @genes.grn.val
    @blu = @genes.blu.val



  chooseAction: (energy, observables) ->
    # an observable is a [blob, distance] pair

    if ALWAYS_REPRODUCE
      return {"type": "repr", "argument": 0}
    huntPairs = ([@calcHuntImpulse(o), o] for o in observables)
    fleePairs = ([@calcFleeImpulse(o), o] for o in observables)

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

  calcColorDist: (b) -> 
    # high value indicates high distance
    # negative value indicates closeness
    dred = Math.abs(b.red - @red)
    dgrn = Math.abs(b.grn - @grn)
    dblu = Math.abs(b.blu - @blu)
    dred + dgrn + dblu - 10


  calcHuntImpulse: ([b, dist]) -> 
    i =  @genes.nrgHunt.val * b.energy
    i += @genes.atkHunt.val * (b.atk - @atk)
    i += @genes.spdHunt.val * (b.spd - @spd)
    i += @genes.phoHunt.val * b.pho
    i += @genes.effHunt.val * b.eff
    i += @genes.dstHunt.val * dist
    i += @genes.clrHunt.val * @calcColorDist(b)
  
  calcFleeImpulse: ([b, dist]) -> 
    i =  @genes.nrgFlee.val * b.energy
    i += @genes.atkFlee.val * (b.atk - @atk)
    i += @genes.spdFlee.val * (b.spd - @atk)
    i += @genes.phoFlee.val * b.pho
    i += @genes.effFlee.val * b.eff
    i += @genes.dstFlee.val * dist
    i += @genes.clrFlee.val * @calcColorDist(b)

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
    @mutationProbability = C.MUTATION_PROBABILITY

  mutate: () ->
    if Math.random() < @mutationProbability
      sign = randomSign()
      mutationSize = @mutationSize * 2 * Math.random() * C.MUTATION_CONSTANT
      @val += sign * mutationSize
      @val = Math.max @val, @min
      @val = Math.min @val, @max
    this
