env = new Environment(5, null)

for i in [0...2000]
	env.step()
	console.log env.nBlobs
	