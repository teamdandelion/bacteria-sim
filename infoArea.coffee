class InfoArea
  constructor: (@p, @e) -> 

  draw: () ->
    @p.pushMatrix()
    @p.translate(0, C.DISPLAY_Y)
    @makeRect()
    @blob = @e.observedBlob
    if @blob?
      @printInfo(@blob)

    @p.popMatrix()

  makeRect: () ->
    @p.strokeWeight(6)
    @p.stroke(0)
    @p.fill(0) 
    @p.rect(0,0,C.DISPLAY_X,C.DISPLAY_BOUND)
    @p.noStroke()

  printInfo: (blob) -> 
    @offset = 0
    @p.fill(255)
    geneStats = "ATK: #{@fmt(blob.atk)} SPD: #{@fmt(blob.spd)} PHO: #{@fmt(blob.pho)} EFF: #{@fmt(blob.eff)}"
    otherStats = "Energy: #{@fmt(blob.energy)} Age: #{@fmt(blob.age)} EPS: #{@fmt(blob.energyPerSecond)} Attack Power: #{@fmt(blob.attackPower)}"
    attackInfo = "Attacked #{@fmt blob.numAttacks}, total #{@fmt blob.attackEnergyThisTurn} energy xfer"

    @writeLine(geneStats)
    @writeLine(otherStats)
    @writeLine(attackInfo)
    @writeAction(blob)

  writeAction: (blob) ->
    action = blob.action
    if action.type == "flee" or action.type == "hunt"
      if action.argument?
        argument = action.argument[0].id
      else
        argument = "none"
    else if action.type == "repr"
      argument = @fmt(action.argument)
    else
      argument = "none"
    @writeLine "Action: #{action.type}, Argument: #{argument}"

  writeLine: (s) -> 
    @offset += 20
    @p.text(s, 10, @offset)



  fmt: (num) ->
    Math.round(num)

