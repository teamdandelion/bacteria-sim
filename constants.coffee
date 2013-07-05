class C
  # Environment variables
  @X_MARGIN = 100
  @Y_MARGIN = 100
  # these stop blobs from flickering at margins, although at the expense of
  # computing 100 pixels in each direction of spcae that isnt displayed
  # if drawing code is improved to handle wraparounds elegantly then this will
  # be unnecessary. its a hack.
  @DISPLAY_X = 1000
  @DISPLAY_Y = 500

  @X_BOUND = @DISPLAY_X + 2 * @X_MARGIN
  @Y_BOUND = @DISPLAY_Y + 2 * @Y_MARGIN
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = off # change display bound if you turn this on

  @SMALL_SIZE  = 10
  @MEDIUM_SIZE = 30
  @LARGE_SIZE  = 60
  @HUGE_SIZE   = 200
  
  @TWO_TRADEOFF = off
  @HARSH_REPRODUCTION = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 20
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 400
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100

  @REPR_ENERGY_COST    = 700
  @MOVEMENT_SPEED_FACTOR = .05
  @PHO_EPS =  .1
  @PHO_SQ_EPS = .06
  @ATK_EPS = -.5
  @ATK_SQ_EPS = 0
  @SPD_EPS = 0
  @AGE_ENERGY_DECAY = .001
  @RADIUS_FACTOR = .2
  @RADIUS_CONSTANT = 3 
  @BLOB_SIZE = 1.0 # single scaling factor
  @ENERGY_DECAY = .005
  @REPR_TIME_REQUIREMENT = 7

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 30
  @MOVE_UPDATE_AMT = 5
