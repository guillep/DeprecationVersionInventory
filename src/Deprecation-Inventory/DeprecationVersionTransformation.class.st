"
I add the Pharo version found by a DeprecationVersionInventory to every deprecation that lacks it, in bulk, as one refactoring that can be previewed before it is applied.

	self deprecated: 'Use #foo' transformWith: rule
becomes
	self deprecated: 'Use #foo' on: '2025-03-01' in: #Pharo14 transformWith: rule

The date is the one of the commit that deprecated the method when the history gave it, and 'unknown' otherwise. An existing on: date is kept, and an unreadable in: version is replaced. Entries without a version are left alone.

	(DeprecationVersionTransformation entries: inventory entries) generateChanges.
	(DeprecationVersionTransformation entries: inventory entries) execute.
"
Class {
	#name : 'DeprecationVersionTransformation',
	#superclass : 'RBCompositeTransformation',
	#instVars : [
		'entries'
	],
	#category : 'Deprecation-Inventory',
	#package : 'Deprecation-Inventory'
}

{ #category : 'instance creation' }
DeprecationVersionTransformation class >> entries: aCollectionOfDeprecationVersionEntries [

	^ self new setEntries: aCollectionOfDeprecationVersionEntries
]

{ #category : 'executing' }
DeprecationVersionTransformation >> buildTransformations [

	^ (entries select: [ :each | each isFound ]) collect: [ :each |
		  RBAddMethodTransformation
			  model: self model
			  sourceCode: (self sourceWithVersionFor: each)
			  in: each method methodClass
			  withProtocol: each method protocolName ]
]

{ #category : 'rewriting' }
DeprecationVersionTransformation >> dateStringOf: anEntry [

	^ anEntry date ifNil: [ 'unknown' ] ifNotNil: [ :date | date asDate yyyymmdd ]
]

{ #category : 'rewriting' }
DeprecationVersionTransformation >> send: aSendNode withVersionOf: anEntry [
	"Rewrite a deprecation send as deprecated:on:in:, keeping its explanation, its on: date when it had one, and its transformWith: and when: arguments."

	| arguments |
	arguments := Dictionary new.
	aSendNode keywords with: aSendNode arguments do: [ :keyword :argument | arguments at: keyword put: argument sourceCode ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'self deprecated: ';
			  nextPutAll: (arguments at: #deprecated:);
			  nextPutAll: ' on: ';
			  nextPutAll: (arguments at: #on: ifAbsent: [ (self dateStringOf: anEntry) printString ]);
			  nextPutAll: ' in: #Pharo';
			  print: anEntry version.
		  #( #transformWith: #when: ) do: [ :keyword |
			  arguments at: keyword ifPresent: [ :argument |
				  stream
					  space;
					  nextPutAll: keyword;
					  space;
					  nextPutAll: argument ] ] ]
]

{ #category : 'initialization' }
DeprecationVersionTransformation >> setEntries: aCollection [

	entries := aCollection
]

{ #category : 'rewriting' }
DeprecationVersionTransformation >> sourceWithVersionFor: anEntry [
	"The source of the entry's method with its version added to every deprecation send lacking one. Sends are replaced from the last to the first so that earlier positions stay valid."

	| source inventory sends |
	source := anEntry method sourceCode.
	inventory := DeprecationVersionInventory new.
	sends := anEntry method parseTree sendNodes select: [ :each |
		         each receiver isSelfVariable and: [
			         (inventory deprecationSelectors includes: each selector) and: [ (inventory statesVersion: each) not ] ] ].
	(sends asArray sort: [ :a :b | a start > b start ]) do: [ :each |
		source := source copyReplaceFrom: each start to: each stop with: (self send: each withVersionOf: anEntry) ].
	^ source
]
