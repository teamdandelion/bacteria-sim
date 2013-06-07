class C
  # Environment variables
  @X_MARGIN = 100
  @Y_MARGIN = 100
  # these stop blobs from flickering at margins, although at the expense of
  # computing 100 pixels in each direction of spcae that isnt displayed
  # if drawing code is improved to handle wraparounds elegantly then this will
  # be unnecessary. its a hack.
  @DISPLAY_X = window.innerWidth  - 20 ? 1000
  @DISPLAY_Y = window.innerHeight - 20 ? 500

  @X_BOUND = @DISPLAY_X + 2 * @X_MARGIN
  @Y_BOUND = @DISPLAY_Y + 2 * @Y_MARGIN
  @DISPLAY_BOUND = 0
  @INFO_WINDOW = on # change display bound if you turn this on

  
  @HARSH_REPRODUCTION = off

  @NEIGHBOR_DISTANCE = 20
  @CHILD_DISTANCE    = 60
  @ATTACK_MARGIN     = 100
  @STARTING_ENERGY   = 200
  @STARTING_BLOBS    = 20
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100
  @MOVE_SPEED = 1
  @RED_ENERGY = 5.0
  @GRN_ENERGY = 5.0
  @BLU_ENERGY = 5.0
  @BASE_EPS = -5

  @REPR_ENERGY_COST    = 700
  @AGE_ENERGY_DECAY = .001 #NOT IMPLEMENTED
  @RADIUS_FACTOR = .2
  @RADIUS_CONSTANT = 3 
  @BLOB_SIZE = 1.0 # single scaling factor
  @ENERGY_DECAY = .005 #NOT IMPLEMENTED
  @REPR_TIME_REQUIREMENT = 7
  @CLUMP_PENALTY = 10

  @MUTATION_PROBABILITY = .1
  @MUTATION_CONSTANT = .5

  # Backend variables
  @QTREE_BUCKET_SIZE = 50
  @FRAME_RATE = 30
  @MOVE_UPDATE_AMT = 5
