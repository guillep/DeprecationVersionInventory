"
I find the Pharo version in which each deprecation of the image was introduced, for deprecations that do not state it (PHEP-0004 asks them to).

A method in a DeprecatedN package (Deprecated14, Deprecated13-Kernel) was deprecated in Pharo N. Otherwise I look in the git history of the method for the oldest commit sending #deprecated:, and answer the first Pharo version released after that commit, using the release tags (v12.0.0) of the repository.

	(DeprecationVersionInventory repository: (IceRepository registeredRepositoryIncludingPackage: Deprecation package)) entries
"
Class {
	#name : 'DeprecationVersionInventory',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'releaseDates'
	],
	#category : 'Deprecation-Inventory',
	#package : 'Deprecation-Inventory'
}

{ #category : 'instance creation' }
DeprecationVersionInventory class >> repository: anIceRepository [

	^ self new setRepository: anIceRepository
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

{ #category : 'inventory' }
DeprecationVersionInventory >> entryFor: aMethod [

	(self versionFromPackageOf: aMethod) ifNotNil: [ :version |
		^ DeprecationVersionEntry method: aMethod version: version source: #package ].
	(self versionFromHistoryOf: aMethod) ifNotNil: [ :version |
		^ DeprecationVersionEntry method: aMethod version: version source: #history ].
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

{ #category : 'inventory' }
DeprecationVersionInventory >> methodsWithoutVersion [

	| selectors methods |
	selectors := self deprecationSelectors.
	methods := Set new.
	selectors do: [ :each | methods addAll: (SystemNavigation default allReferencesTo: each) ].
	^ (methods select: [ :each | self isDeprecatedWithoutVersion: each compiledMethod ] thenCollect: [ :each | each compiledMethod ])
		  asArray sort: [ :a :b | a name <= b name ]
]

{ #category : 'versions' }
DeprecationVersionInventory >> releaseDates [
	"Major version -> date of its release tag (v12.0.0)."

	^ releaseDates ifNil: [
		  | matcher |
		  matcher := '^v(\d+)\.0\.0$' asRegex.
		  releaseDates := Dictionary new.
		  repository tags do: [ :each |
			  (matcher matches: each name) ifTrue: [ releaseDates at: (matcher subexpression: 2) asNumber put: each commit datetime ] ].
		  releaseDates ]
]

{ #category : 'accessing' }
DeprecationVersionInventory >> releaseDates: aDictionary [
	"Major version -> release date, instead of reading them from the repository tags."

	releaseDates := aDictionary
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
DeprecationVersionInventory >> versionDevelopedAt: aDateAndTime [
	"The first major version released after aDateAndTime, or the current one when none was."

	| released |
	released := self releaseDates associations select: [ :each | each value > aDateAndTime ].
	released ifEmpty: [ ^ SystemVersion current major ].
	^ (released detectMin: [ :each | each key ]) key
]

{ #category : 'versions' }
DeprecationVersionInventory >> versionFromHistoryOf: aMethod [
	"The Pharo version under development when the oldest commit sending #deprecated: in aMethod was made, nil when the method is in no repository or its history has none. The method's own repository is asked: Spec, Microdown or Roassal live in theirs, while release dates come from the Pharo repository."

	| methodRepository history firstDeprecated |
	methodRepository := IceRepository registeredRepositoryIncludingPackage: aMethod package.
	methodRepository ifNil: [ ^ nil ].
	history := (methodRepository logClass for: methodRepository) historyOfMethod: aMethod.
	firstDeprecated := history reversed
		                   detect: [ :each | each definition sourceCode includesSubstring: 'deprecated:' ]
		                   ifNone: [ ^ nil ].
	^ self versionDevelopedAt: firstDeprecated datetime
]

{ #category : 'versions' }
DeprecationVersionInventory >> versionFromPackageOf: aMethod [
	"Pharo N for a method of a DeprecatedN package, nil otherwise."

	| matcher |
	matcher := '^Deprecated(\d+)' asRegex.
	(matcher search: aMethod package name) ifFalse: [ ^ nil ].
	^ (matcher subexpression: 2) asNumber
]
