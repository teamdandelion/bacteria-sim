env = new Environment(1, null)
blob = env.blobs[0]
console.log blob

console.log(blob.energyPerSecond)
for i in [0...2]
	env.step()
	console.log blob.energy