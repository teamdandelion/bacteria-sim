class Simulation
  constructor: (@p) -> 
    # assumption: The bounds of environment are 
    # greater than the display bounds, so when 
    # blobs wrap around we don't need to worry about
    # displaying them at both edges of the field 
    # at teh same time
    @env = new Environment(C.STARTING_BLOBS, p)
    @running = on
    @infoArea = new InfoArea(@p, @env)
    @xLower = 100
    @yLower = 100
    @xUpper = 100 + C.DISPLAY_X
    @yUpper = 100 + C.DISPLAY_Y
    @showNucleus = on

  step: () -> 
    if @running
      @env.step()
      @drawAll()

  keyCode: (k) -> 
    if k == 32 # 'space'
      @running = !@running
    if k == 78 # 'n'
      @showNucleus = !@showNucleus

  mouseClick: (x, y) -> 
    @env.observeBlob(x+100,y+100)
    if !@running
      @drawAll()

  drawAll: () -> 
    @p.background(0)
    for blobID, blob of @env.blobs
      pos = @env.qtree.id2point[blobID]
      @drawBlob(blob, pos)
    @infoArea.draw()


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

      
      red = blob.atk * 2.55
      grn = blob.pho * 2.55
      blu = blob.spd * 2.55
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

      if blob.reproducing?
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