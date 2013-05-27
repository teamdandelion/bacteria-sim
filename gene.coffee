class GeneCode
	@randomP100  = () -> Math.floor(Math.random()*100)
	@randomPN100 = () -> Math.floor(Math.random()*200) - 100
	constructor: () ->
		genes = 
			atkGene: Gene(0,100,1)
			spdGene: Gene(0,100,1)
			phoGene: Gene(0,100,1)
			effGene: Gene(0,100,1)
			# neural threhsolds are calculated as base + modifier * energy
			huntBase: Gene()
			fleeBase: Gene()
			reprBase: Gene()
			huntMod:  Gene()
			fleeMod:  Gene()
			reprMod:  Gene()
			
			nrgHunt: Gene()
			atkHunt: Gene()
			spdHunt: Gene()
			phoHunt: Gene()
			effHunt: Gene()
			

			nrgFlee: Gene()
			atkFlee: Gene()
			spdFlee: Gene()
			phoFlee: Gene()

		@mutationFrequency = .05

		

		# Hunt and Flee stats: Mapping from another creature's stats
		# to hunt or flee weighting
		# Stats: Energy, Atk, Spd, Pho, Eff
		@huntStats = (Gene(-10,10,1) for g in [0...5])
		@fleeStats = (Gene(-10,10,1) for g in [0...5])


class Gene
	constructor: (@min=-100, @max=100, @mutability=1) ->
		@val = Math.random() * (@max-@min) + @min

	mutate: (p) ->
		if Math.random() < p
			sign = randomSign()
			mutationSize = @mutability * 2 * Math.random()
			@val += sign * mutationSize


