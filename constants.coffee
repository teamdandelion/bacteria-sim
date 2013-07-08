class C
  # Environment variables

  @X_BOUND = $(window).width()
  @Y_BOUND = $(window).height()
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = off # change display bound if you turn this on
  
  @TWO_TRADEOFF = off
  @HARSH_REPRODUCTION = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 20
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 100
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100

  @REPR_ENERGY_COST    = 2000
  @MOVEMENT_SPEED_FACTOR = .3
  @PHO_EPS =  .05
  @PHO_SQ_EPS = .15
  @ATK_EPS = -.5
  @ATK_SQ_EPS = 0
  @SPD_EPS = 0
  @AGE_ENERGY_DECAY = .5
  @RADIUS_FACTOR = .1
  @RADIUS_CONSTANT = 1 
  @BLOB_SIZE = 1.0 # single scaling factor
  @ENERGY_DECAY = .005
  @REPR_TIME_REQUIREMENT = 7

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 60
  @MOVE_UPDATE_AMT = 5
