env = new Environment(250, null)

for i in [0...1000]
	env.step()
	console.log env.nBlobs
	