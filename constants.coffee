class C
  # Environment variables
  @X_BOUND = 1000
  @Y_BOUND = 500
  @NEIGHBOR_DISTANCE = 100
  @CHILD_DISTANCE    = 80
  @ATTACK_DISTANCE   = 20
  @STARTING_ENERGY   = 400
  
  # Blob variables
  @MOVEMENT_PER_ENERGY = 100
  @REPR_ENERGY_COST    = 800
  @MOVEMENT_SPEED_FACTOR = .01
  @PHO_EPS =  1
  @ATK_EPS = -0.3
  @SPD_EPS = -0.3
  @AGE_ENERGY_DECAY = .001


  # Backend variables
  @QTREE_BUCKET_SIZE = 100