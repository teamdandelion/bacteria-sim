
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
			atkGene: new Gene(0,100,1)
			spdGene: new Gene(0,100,1)
			phoGene: new Gene(0,100,1)
			effGene: new Gene(0,100,1)
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
			dstHunt: new Gene()

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
