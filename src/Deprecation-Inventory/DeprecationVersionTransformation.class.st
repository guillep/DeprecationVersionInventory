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
DeprecationVersionTransformation >> explanationSourceOf: anArgumentNode [
	"The explanation without the Pharo version some authors wrote in it ('Use #foo instead. #Pharo14'): the version now goes in in:, and a copy in the text could contradict it."

	| text |
	(anArgumentNode isLiteralNode and: [ anArgumentNode value isString ]) ifFalse: [ ^ anArgumentNode sourceCode ].
	text := anArgumentNode value copyWithRegex: '\s*#[Pp]haro\d+' matchesReplacedWith: ''.
	text = anArgumentNode value ifTrue: [ ^ anArgumentNode sourceCode ].
	^ text trimBoth printString
]

{ #category : 'rewriting' }
DeprecationVersionTransformation >> indentationOf: aString at: anIndex [
	"The tabs and spaces that start the line holding anIndex."

	| lineStart lineEnd |
	lineStart := anIndex.
	[ lineStart > 1 and: [ (String crlf includes: (aString at: lineStart - 1)) not ] ] whileTrue: [ lineStart := lineStart - 1 ].
	lineEnd := lineStart.
	[ lineEnd < anIndex and: [ (aString at: lineEnd) isSeparator ] ] whileTrue: [ lineEnd := lineEnd + 1 ].
	^ aString copyFrom: lineStart to: lineEnd - 1
]

{ #category : 'rewriting' }
DeprecationVersionTransformation >> send: aSendNode withVersionOf: anEntry indentation: aString [
	"Rewrite a deprecation send as deprecated:on:in:, one keyword per line, keeping its explanation, its on: date when it had one, and its transformWith: and when: arguments."

	| arguments keywords |
	arguments := Dictionary new.
	aSendNode keywords with: aSendNode arguments do: [ :keyword :argument | arguments at: keyword put: argument ].
	keywords := OrderedCollection new.
	keywords
		add: #deprecated: -> (self explanationSourceOf: (arguments at: #deprecated:));
		add: #on: -> ((arguments at: #on: ifAbsent: [ nil ])
			 ifNil: [ (self dateStringOf: anEntry) printString ]
			 ifNotNil: [ :argument | argument sourceCode ]);
		add: #in: -> ('#Pharo' , anEntry version printString).
	#( #transformWith: #when: ) do: [ :keyword |
		arguments at: keyword ifPresent: [ :argument | keywords add: keyword -> argument sourceCode ] ].
	^ String streamContents: [ :stream |
		  stream nextPutAll: 'self'.
		  keywords do: [ :each |
			  stream
				  newLine;
				  nextPutAll: aString;
				  tab;
				  nextPutAll: each key;
				  space;
				  nextPutAll: each value ] ]
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
		source := source
			          copyReplaceFrom: each start
			          to: each stop
			          with: (self send: each withVersionOf: anEntry indentation: (self indentationOf: source at: each start)) ].
	^ source
]
