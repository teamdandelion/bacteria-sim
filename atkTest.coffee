attack = (b1, b2) -> 
  redDelta = b1.red * b2.grn - b2.red * b1.grn
  grnDelta = b1.grn * b2.blu - b2.grn * b1.blu
  bluDelta = b1.blu * b2.red - b2.blu * b1.red
  attackDelta = redDelta + grnDelta + bluDelta

cb = (r,g,b) -> 
	{'red':r, 'grn':g, 'blu':b}

attack_draw = (p) -> 
	p.setup = () -> 
		p.background(0)
		R = cb(255,0,0)
		G = cb(0,255,0)
		B = cb(0,0,255)
		RG = cb(255/2,255/2,0)
		RB = cb(255/2,0,255/2)
		GB = cb(0,255/2,255/2)
		RGB = cb(255/3, 255/3, 255/3)
		colors = [R,G,B,RG,RB,GB,RGB]
		for c1 in colors
			for c2 in colors
				

