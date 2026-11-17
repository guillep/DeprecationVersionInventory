"
I find the Pharo version in which each deprecation of a repository was introduced, for deprecations that do not state it (PHEP-0004 asks them to).

A method in a DeprecatedN package (Deprecated14, Deprecated13-Kernel) was deprecated in Pharo N. Otherwise I look in the git history of the method for the oldest commit sending #deprecated:, and answer the first Pharo version whose release tag (v12.0.0) includes that commit, or the version under development when no release does yet.

	(DeprecationVersionInventory repository: (IceRepository registeredRepositoryIncludingPackage: Deprecation package)) entries
"
Class {
	#name : 'DeprecationVersionInventory',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#category : 'Deprecation-Inventory',
	#package : 'Deprecation-Inventory'
}

{ #category : 'instance creation' }
DeprecationVersionInventory class >> repository: anIceRepository [

	^ self new setRepository: anIceRepository
]

{ #category : 'versions' }
DeprecationVersionInventory >> deprecationCommitOf: aMethod [
	"The oldest commit sending #deprecated: in aMethod, nil when the method is in no repository or its history has none."

	| methodRepository history firstDeprecated |
	methodRepository := IceRepository registeredRepositoryIncludingPackage: aMethod package.
	methodRepository ifNil: [ ^ nil ].
	history := (methodRepository logClass for: methodRepository) historyOfMethod: aMethod.
	firstDeprecated := history reversed
		                   detect: [ :each | each definition sourceCode includesSubstring: 'deprecated:' ]
		                   ifNone: [ ^ nil ].
	^ firstDeprecated commit
]

{ #category : 'versions' }
DeprecationVersionInventory >> deprecationDateOf: aMethod [

	^ (self deprecationCommitOf: aMethod) ifNotNil: [ :commit | commit datetime ]
]

{ #category : 'inventory' }
DeprecationVersionInventory >> deprecationSelectors [

	^ #( #deprecated: #deprecated:transformWith: #deprecated:transformWith:when: #deprecated:on:in: #deprecated:on:in:transformWith:
	     #deprecated:on:in:transformWith:when: )
]

{ #category : 'inventory' }
DeprecationVersionInventory >> entries [
	"One entry per deprecated method of the image that does not state its Pharo version."

	^ self methodsWithoutVersion collect: [ :each | self entryFor: each ]
]

{ #category : 'versions' }
DeprecationVersionInventory >> entryFor: aMethod [

	(self versionFromPackageOf: aMethod) ifNotNil: [ :version |
		^ DeprecationVersionEntry method: aMethod version: version source: #package ].
	(self deprecationCommitOf: aMethod) ifNotNil: [ :commit |
		^ (DeprecationVersionEntry method: aMethod version: (self versionContaining: commit) source: #history)
			  date: commit datetime;
			  yourself ].
	^ DeprecationVersionEntry method: aMethod version: nil source: #unknown
]

{ #category : 'testing' }
DeprecationVersionInventory >> isDeprecatedWithoutVersion: aMethod [
	"Whether aMethod sends a deprecation message to self without a readable Pharo version."

	| sends |
	sends := aMethod ast sendNodes select: [ :each |
		         each receiver isSelfVariable and: [ self deprecationSelectors includes: each selector ] ].
	^ sends notEmpty and: [ sends anySatisfy: [ :each | (self statesVersion: each) not ] ]
]

{ #category : 'testing' }
DeprecationVersionInventory >> isInRepository: aMethod [
	"Without a repository, every method of the image is inventoried."

	repository ifNil: [ ^ true ].
	^ repository includesPackageNamed: aMethod package name
]

{ #category : 'inventory' }
DeprecationVersionInventory >> methodsWithoutVersion [
	"The deprecated methods without a stated version that belong to the inventoried repository: PHEP-0004 applies to the code of that repository only, not to the projects loaded beside it."

	| methods |
	methods := Set new.
	self deprecationSelectors do: [ :each | methods addAll: (SystemNavigation default allReferencesTo: each) ].
	^ (methods
		   collect: [ :each | each compiledMethod ]
		   thenSelect: [ :each | (self isInRepository: each) and: [ self isDeprecatedWithoutVersion: each ] ]) asArray sort: [ :a :b |
		  a name <= b name ]
]

{ #category : 'versions' }
DeprecationVersionInventory >> releaseCommits [
	"Major version -> commit of its release tag (v12.0.0)."

	| matcher commits |
	matcher := '^v(\d+)\.0\.0$' asRegex.
	commits := Dictionary new.
	repository tags do: [ :each |
		(matcher matches: each name) ifTrue: [ commits at: (matcher subexpression: 2) asNumber put: each commit ] ].
	^ commits
]

{ #category : 'accessing' }
DeprecationVersionInventory >> repository [

	^ repository
]

{ #category : 'initialization' }
DeprecationVersionInventory >> setRepository: anIceRepository [

	repository := anIceRepository
]

{ #category : 'testing' }
DeprecationVersionInventory >> statesVersion: aSendNode [
	"A version given by an expression rather than a literal is taken as stated."

	| index argument |
	index := aSendNode keywords indexOf: #in: ifAbsent: [ ^ false ].
	argument := aSendNode arguments at: index.
	argument isLiteralNode ifFalse: [ ^ true ].
	^ (Deprecation new
		   version: argument value;
		   deprecationMajorVersion) notNil
]

{ #category : 'versions' }
DeprecationVersionInventory >> versionContaining: aCommit [
	"The first major version whose release tag includes aCommit, or the version under development when no release does yet. A commit is included in a release when it is its own merge base with the release commit: this follows branches and backports, unlike dates."

	| released |
	released := self releaseCommits associations select: [ :each |
		            (aCommit commonAncestorWithCommit: each value) ifNil: [ false ] ifNotNil: [ :base | base id = aCommit id ] ].
	released ifEmpty: [ ^ SystemVersion current major ].
	^ (released detectMin: [ :each | each key ]) key
]

{ #category : 'versions' }
DeprecationVersionInventory >> versionFromHistoryOf: aMethod [
	"The first Pharo version released with the commit that deprecated aMethod, nil when its history does not say."

	^ (self deprecationCommitOf: aMethod) ifNotNil: [ :commit | self versionContaining: commit ]
]

{ #category : 'versions' }
DeprecationVersionInventory >> versionFromPackageOf: aMethod [
	"Pharo N for a method of a DeprecatedN package, nil otherwise."

	| matcher |
	matcher := '^Deprecated(\d+)' asRegex.
	(matcher search: aMethod package name) ifFalse: [ ^ nil ].
	^ (matcher subexpression: 2) asNumber
]
