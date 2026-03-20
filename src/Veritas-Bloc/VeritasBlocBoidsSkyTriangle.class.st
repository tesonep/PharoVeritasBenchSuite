Class {
	#name : 'VeritasBlocBoidsSkyTriangle',
	#superclass : 'VeritasBenchSuite',
	#category : 'Veritas-Bloc',
	#package : 'Veritas-Bloc'
}

{ #category : 'api' }
VeritasBlocBoidsSkyTriangle >> run [

	BlBBoidsSkyCase new
		label: 'BlBBoidsSkyCase using triangle geometry';
		element: BoidsUsingTriangleSkyElement new;
		runner: (BlBBlocBenchFrameRunner forFrames: 500);
		run
]
