class Simulation
  constructor: (@p) -> 
    # assumption: The bounds of environment are 
    # greater than the display bounds, so when 
    # blobs wrap around we don't need to worry about
    # displaying them at both edges of the field 
    # at teh same time
    @env = new Environment(C.STARTING_BLOBS, p)
    console.log @env.blobs
    
    opt = {}
    opt['Kill all blobs'] = () => 
      @env.killAllBlobs()
    opt['Add a blob'] = () =>
      @env.addRandomBlob()
    
    gui = new dat.GUI()
    # gui.onChange = () ->
      # console.log "CHANGE RECORDED"
    gui.add(C, 'REPR_ENERGY_COST', 50, 5000)
    gui.add(C, 'BLOB_SIZE', 0.1, 5)
    gui.add(C, 'MUTATION_CONSTANT', .01, 1)
    gui.add(C, 'MUTATION_PROBABILITY', 0, .5)
    gui.add(C, 'ENERGY_DECAY', 0, .1)
    gui.add(C, 'AGE_ENERGY_DECAY', 0, .1)
    gui.add(C, 'RED_ENERGY', 0, 10000)
    gui.add(C, 'GRN_ENERGY', 0, 10000)
    gui.add(C, 'BLU_ENERGY', 0, 10000)
    gui.add(C, 'BASE_EPS', -100, -5)
    gui.add(C, 'CLUMP_PENALTY', 0, 50)
    gui.add(opt, 'Kill all blobs')
    gui.add(opt, 'Add a blob')

    @running = on
    if C.INFO_WINDOW then @infoArea = new InfoArea(@p, @env)
    @xLower = 100
    @yLower = 100
    @xUpper = 100 + C.DISPLAY_X
    @yUpper = 100 + C.DISPLAY_Y
    @showNucleus = off
    @showShells = off
    @showReproduction = off

  step: () -> 
    if @running
      @env.step()
      @drawAll()

  keyCode: (k) -> 
    if k == 32 # 'space'
      @running = !@running
    if k == 78 # 'n'
      @showNucleus = !@showNucleus
    if k == 83 # 's'
      @showShells = !@showShells
    if k == 82 # 'r'
      @showReproduction = !@showReproduction

  mouseClick: (x, y) -> 
    if C.INFO_WINDOW
      @env.observeBlob(x+100,y+100)
      if !@running
        @drawAll()


  drawAll: () -> 
    @p.background(0)
    for blobID, blob of @env.blobs
      pos = @env.location[blobID]
      @drawBlob(blob, pos)
    if C.INFO_WINDOW then @infoArea.draw()


  drawBlob: (blob, position) -> 
    r = blob.rad
    x = position.x
    y = position.y
    # These are coordinates relative to the upper-left
    # hand corner of the viewing area
    intersectX = x+r > @xLower or x-r < @xUpper
    intersectY = y+r > @yLower or y-r < @yUpper
    if intersectX and intersectY
      x-= @xLower
      y-= @yLower
      @p.noStroke()

      
      red = blob.red
      grn = blob.grn
      blu = blob.blu
      @p.fill(red,grn,blu)

      # if blob.rad < C.SMALL_SIZE
      #   @p.fill(255,0,0)
      # else if blob.rad < C.MEDIUM_SIZE
      #   @p.fill(0,255,0)
      # else if blob.rad < C.LARGE_SIZE
      #   @p.fill(0,0,255)
      # else if blob.rad < C.HUGE_SIZE
      #   @p.fill(255,255,0)
      # else
      #   @p.fill(255)
      if blob.observed?
        @p.strokeWeight(1)
        @p.stroke(255)
      
      @p.ellipse(x, y, 2*r, 2*r)

      # nucleus colors
      if @showNucleus
        nuc_red = blob.red
        nuc_grn = blob.grn
        nuc_blu = blob.blu
        @p.fill(nuc_red,nuc_grn,nuc_blu)
        rad = Math.min(3, blob.rad/2)
        @p.ellipse(x,y,2*rad, 2*rad)

      if @showShells
        nuc_red = blob.red
        nuc_grn = blob.grn
        nuc_blu = blob.blu
        @p.stroke(nuc_red,nuc_grn,nuc_blu)
        @p.noFill()
        rad = blob.rad
        @p.strokeWeight(2)
        @p.ellipse(x,y,2*rad, 2*rad)


      if @showReproduction and blob.reproducing?
        red2 = Math.min red + 9, 255
        grn2 = Math.min grn + 9, 255
        blu2 = Math.min blu + 9, 255
        @p.noFill()
        @p.stroke(red2,grn2,blu2)
        weight = 5 * (C.REPR_TIME_REQUIREMENT - blob.maintainCurrentAction) / C.REPR_TIME_REQUIREMENT
        @p.strokeWeight(weight)
        @p.ellipse(x, y, 2*r-5, 2*r-5)



      

simulator_draw = (p) -> 
  s = new Simulation(p)
  p.mouseClicked = () -> 
    s.mouseClick(p.mouseX, p.mouseY)
   
  p.setup = () ->
    p.frameRate(C.FRAME_RATE)
    p.size(C.DISPLAY_X, C.DISPLAY_Y + C.DISPLAY_BOUND)
    p.background(0,20,90)

  p.draw = () ->
    s.step()

  p.keyPressed = () -> 
    console.log p.keyCode
    s.keyCode(p.keyCode)

# wait for the DOM to be ready, 
# create a processing instance...
$(document).ready ->
  canvas = document.getElementById "processing"

  processing = new Processing(canvas, simulator_draw)