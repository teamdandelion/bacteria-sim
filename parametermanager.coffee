class ParameterManager
  """Manages blob parameters presents them in a GUI interface to the user.
  Handles passing new parameter information to the simulation when they are updated."""
  constructor: (@simulation) ->
    @configs = {} # name -> config object

	addConfig: (name, folder=undefined, prettyName, default, min, max, visible=yes) ->
    c = {name: name, folder: folder, prettyName: prettyName, min: min, max: max, visible:visible}
    @configs[name] = c
    @values[name] = default

  getValuesList: () ->
    v = {}
    for name, val of @values
      v[name] = val
    v

  randomize: () ->
    for name, config of @configs
      @values[name] = Math.random() * (config.max - config.min) + config.minw










	@TWO_TRADEOFF = off
	@HARSH_REPRODUCTION = off
	@STARTING_ENERGY   = 200
	# Blob variables
	@MOVEMENT_PER_ENERGY = 100
	@REPR_ENERGY_COST    = 2000
	@MOVEMENT_SPEED_FACTOR = .3
	@PHO_EPS =  .1
	@PHO_SQ_EPS = .15
	@ATK_EPS = -.5
	@ATK_SQ_EPS = 0
	@SPD_EPS = 0
	@AGE_ENERGY_DECAY = 1
	@RADIUS_FACTOR = .1
	@RADIUS_CONSTANT = 1 
	@BLOB_SIZE = 1.0 # single scaling factor
	@ENERGY_DECAY = .005
	@REPR_TIME_REQUIREMENT = 7

	@MUTATION_PROBABILITY = .1
	@MUTATION_CONSTANT = .5