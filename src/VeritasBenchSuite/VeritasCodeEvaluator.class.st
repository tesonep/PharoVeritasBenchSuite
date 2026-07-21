Class {
	#name : 'VeritasCodeEvaluator',
	#superclass : 'ClapCodeEvaluator',
	#instVars : [
		'initialStats',
		'finalStats'
	],
	#category : 'VeritasBenchSuite',
	#package : 'VeritasBenchSuite'
}

{ #category : 'command line' }
VeritasCodeEvaluator class >> commandSpecification [
	<commandline>
	| spec |
	spec := (ClapCommandSpec id: #bench)
		commandClass: self;
		description: 'A command that evaluates a Pharo expression, outputs the evaluated result, statistics in rebench format, and quits the image.';
		addHelp;
		addPositional: #EXPR spec: [ :positional |
			positional
				description: 'The Pharo expression to evaluate, joining successive arguments with spaces (if omitted, read the expression from stdin)';
				multiple: true;
				defaultValue: [ :match | "in the absence of an explicit argument, read from standard input"
					Array with: match context stdin upToEnd ] ];
		yourself.
		
	self 
		addSaveFlagTo: spec;
		addKeepAliveOptionTo: spec;
		addNoQuitOptionTo: spec;
		addRenameOptionTo: spec.
	^ spec
]

{ #category : 'execution' }
VeritasCodeEvaluator >> captureFinalStats [

	finalStats := self captureStats.
]

{ #category : 'execution' }
VeritasCodeEvaluator >> captureInitialStats [

	initialStats := self captureStats.
]

{ #category : 'execution' }
VeritasCodeEvaluator >> captureStats [

	^ { Time millisecondClockValue. 
	    Smalltalk vm totalGCTime. 
	    Smalltalk vm compiledMethodsCount. 
	    Smalltalk vm compiledBlocksCount. 
	    Smalltalk vm totalJITCompileTime. 
	    (Smalltalk vm parameterAt: 62)  "Number of Code compactions"
		 }
]

{ #category : 'execution' }
VeritasCodeEvaluator >> evaluateExpression [
	
	| result |
	
	^ [   self captureInitialStats.
			result := OpalEvaluator new evaluate: self source.
			self captureFinalStats.
			self outputStats.
			result ]
		on: Error
		do: [ :error | self handleError: error ]
]

{ #category : 'execution' }
VeritasCodeEvaluator >> outputStats [

	 self outputStreamDo: [ :out | 
		self stats associations do: [ :assoc | 
			out 
				nextPutAll: assoc key;
				nextPutAll: ': ';
				print: assoc value;
				lf ].
			
		out lf.
		out nextPutAll: 'Expression output:'.
		out lf. ]
]

{ #category : 'execution' }
VeritasCodeEvaluator >> stats [

	^ { 
		'benchTime' -> ((finalStats at: 1) - (initialStats at:1)).
		'benchTotalGCTime' -> ((finalStats at: 2) - (initialStats at:2)).
		'benchCompiledMethodsCount' -> ((finalStats at: 3) - (initialStats at:3)).
		'benchCompiledBlocksCount' -> ((finalStats at: 4) - (initialStats at:4)).
		'benchTotalJITCompileTime' -> ((finalStats at: 5) - (initialStats at:5)).
		'benchCodeCompactions' -> ((finalStats at: 6) - (initialStats at:6)).	
		'totalGCTime' -> (finalStats at: 2).
		'totalCompiledMethodsCount' -> (finalStats at: 3).
		'totalCompiledBlocksCount' -> (finalStats at: 4).
		'totalJITCompileTime' -> (finalStats at: 5).
		'totalCodeCompactions' -> (finalStats at: 6)
	 } asOrderedDictionary 
]
