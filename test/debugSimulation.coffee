env = new Environment(100, null)

for i in [0...2000]
	env.step()
	console.log env.nBlobs
	if (i % 60) == 0
		blobs_to_kill = env.nBlobs - 50
		for blob_id, blob of env.blobs
			if blobs_to_kill > 0
				blob.energy = -1000
				blobs_to_kill--