
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
			atkGene: new Gene(null, 0, 100, 1)
			spdGene: new Gene(null, 0, 100, 1)
			phoGene: new Gene(null, 0, 100, 1)
			effGene: new Gene(null, 0, 100, 1)
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

			childEnergy: new Gene(100, 0, 10000, 20)

	calculateAction: (energy, observables) ->
		# an observable is a [blob, distance] pair
		huntPairs = ([@calcHuntImpulse(o), o[0]] for o in observables)
    fleePairs = ([@calcFleeImpulse(o), o[0]] for o in observables)

    maxHunt = maxByIndex(huntPairs, 0) ? [0, null]
    maxFlee = maxByIndex(fleePairs, 0) ? [0, null]

    huntThreshold = @genes.huntBase.val + @genes.huntMod.val * energy
    fleeThreshold = @genes.fleeBase.val + @genes.fleeMod.val * energy
    reprThreshold = @genes.reprBase.val + @genes.reprMod.val * energy
    
    huntSignal = maxHunt[0] - huntThreshold
    fleeSignal = maxFlee[0] - fleeThreshold
    reprSignal = @genes.reprMod.val * energy - reprThreshold   
    fleeAction = [fleeSignal, 'flee', maxFlee[1]]
    huntAction = [huntSignal, 'hunt', maxHunt[1]]
    reprAction = [reprSignal, 'repr', @genes.childEnergy.val]

    signals = [huntSignal, fleeSignal, reprSignal]
    maxSignal = maxByIndex 0, signals

    action = {"type": null}
    if maxSignal[0] > 0
      action.type     = maxSignal[1]
      action.argument = maxSignal[2]
    action

	calculateHuntImpulse: ([o, dist]) -> 
		i =  @genes.nrgHunt * o.nrg
		i += @genes.atkHunt * o.atk
		i += @genes.spdHunt * o.spd
		i += @genes.phoHunt * o.pho
		i += @genes.effHunt * o.eff
		i += @genes.dstHunt * dist
	
	calculateFleeImpulse: ([o, dist]) -> 
		i =  @genes.nrgFlee * o.nrg
		i += @genes.atkFlee * o.atk
		i += @genes.spdFlee * o.spd
		i += @genes.phoFlee * o.pho
		i += @genes.effFlee * o.eff
		i += @genes.dstFlee * dist

class Gene
	"""Represent a single gene in the GeneCode. Has method for mutation.
	In future, plan to change so it references GeneCode and gets mutability
	info from GeneCode. Could be made more efficient by having GeneCodes with
	the same Gene share references to the object."""
	Gene.copy = (old) -> 
		newGene = new Gene(old.val, old.min, old.max, old.mutationSize)
		newGene.mutate()

	constructor: (@val, @min=-100, @max=100, @mutationSize=1) ->
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


