#!/bin/bash

set -x
set -e

REPO_DIR=$(readlink -f $(dirname -- "${BASH_SOURCE[0]}")/../)
BASEDIR=$(pwd)
VM=$BASEDIR/install_vm/Pharo.app/Contents/MacOS/Pharo

mkdir -p image
mkdir -p install_vm

pushd install_vm

if [ ! -f vm.zip ]; then
	curl --progress-bar -o vm.zip https://files.pharo.org/vm/pharo-spur64-headless/$(uname -s)-$(uname -m)/stable10.zip
fi

unzip -o -d . vm.zip  
popd

pushd image

if [ ! -f image.zip ]; then
	curl --progress-bar -o image.zip https://files.pharo.org/image/140/latest-64.zip
fi

unzip -o -d . image.zip
ORIGINAL_IMAGE=$(ls Pharo14.0-SNAPSHOT-*.image)
$VM $ORIGINAL_IMAGE save Bloc

$VM Bloc.image eval --save $(cat <<EOF
	| repositories baselines installedBaselines | 

	Metacello new
		baseline: 'BlocBenchs';
		repository: 'github://pharo-graphics/BlocBenchs:master/src';
		load.

	{
		'alexandrie'.
		'bloc'.
		'album'.
		'toplo'.
		'spec-toplo'.
	} do: [ :repoName |
		(IceRepository registry
			select: [ :each | each name asLowercase = repoName ])
			do:[ :each |
				(each branchNamed: 'dev') checkout.
				each fetch; pull ] ]
		displayingProgress: [ :each | each ].

	repositories := (IceRepository repositories reject: [ :e |
		e project tags includes: 'system' asSymbol ]).

	baselines := (repositories flatCollect: [ :e | e workingCopy packages ])
		select: [:e | e name beginsWith: 'BaselineOf' ] thenCollect: [ :e | e name withoutPrefix: 'BaselineOf'].

	installedBaselines := baselines select: [ :e | Metacello registrations anySatisfy: [ :r | r projectName = e ]].
	
	installedBaselines do: [ :e | 
		Metacello new
			baseline: e;
			lock
		 ].

	Metacello new
		baseline: 'VeritasBloc';
		onConflictUseLoaded;
		repository: 'gitlocal://$REPO_DIR';
		load.
EOF
)

popd