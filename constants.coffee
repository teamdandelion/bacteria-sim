class C
  # Environment variables
  @DISPLAY_X = window.innerWidth  - 20 ? 1000
  @DISPLAY_Y = window.innerHeight - 20 ? 500
  @X_BOUND = @DISPLAY_X + 200
  @Y_BOUND = @DISPLAY_Y + 200
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = off # change display bound if you turn this on

  @SMALL_SIZE  = 10
  @MEDIUM_SIZE = 30
  @LARGE_SIZE  = 60
  @HUGE_SIZE   = 200
  
  @TWO_TRADEOFF = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 5
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 200
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100

  @REPR_ENERGY_COST    = 700
  @MOVEMENT_SPEED_FACTOR = .05
  @PHO_EPS =  -.05
  @PHO_SQ_EPS = .06
  @ATK_EPS = -1
  @ATK_SQ_EPS = -.003
  @SPD_EPS = 0
  @AGE_ENERGY_DECAY = .001
  @RADIUS_FACTOR = .1
  @RADIUS_CONSTANT = 5 
  @ENERGY_DECAY = .005
  @REPR_TIME_REQUIREMENT = 7

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 30
  @MOVE_UPDATE_AMT = 5
