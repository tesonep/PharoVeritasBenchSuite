Class {
	#name : 'VeritasBlocBoxWindmill',
	#superclass : 'VeritasBenchSuite',
	#category : 'Veritas-Bloc',
	#package : 'Veritas-Bloc'
}

{ #category : 'api' }
VeritasBlocBoxWindmill >> run [

	BlBBoxWindmillBlocCase new
		runner: (BlBBlocBenchFrameRunner forFrames: 250);
		run
]
