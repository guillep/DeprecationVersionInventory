"
I am a deprecated method without a stated Pharo version, with the version found for it (nil when none was found), where it came from (#package, #history or #unknown), and the date of the commit that deprecated it when the history gave it.
"
Class {
	#name : 'DeprecationVersionEntry',
	#superclass : 'Object',
	#instVars : [
		'method',
		'version',
		'source',
		'date'
	],
	#category : 'Deprecation-Inventory',
	#package : 'Deprecation-Inventory'
}

{ #category : 'instance creation' }
DeprecationVersionEntry class >> method: aMethod version: aNumber source: aSymbol [

	^ self new setMethod: aMethod version: aNumber source: aSymbol
]

{ #category : 'accessing' }
DeprecationVersionEntry >> date [
	"The date of the commit that deprecated the method, or nil when the version came from its package."

	^ date
]

{ #category : 'accessing' }
DeprecationVersionEntry >> date: aDateAndTime [

	date := aDateAndTime
]

{ #category : 'accessing' }
DeprecationVersionEntry >> isFound [

	^ version notNil
]

{ #category : 'accessing' }
DeprecationVersionEntry >> method [

	^ method
]

{ #category : 'accessing' }
DeprecationVersionEntry >> printOn: aStream [

	aStream
		print: method;
		nextPutAll: ' -> ';
		nextPutAll: (version ifNil: [ '?' ] ifNotNil: [ 'Pharo' , version printString ]);
		nextPutAll: ' (';
		nextPutAll: source;
		nextPut: $)
]

{ #category : 'initialization' }
DeprecationVersionEntry >> setMethod: aMethod version: aNumber source: aSymbol [

	method := aMethod.
	version := aNumber.
	source := aSymbol
]

{ #category : 'accessing' }
DeprecationVersionEntry >> source [
	"#package, #history or #unknown"

	^ source
]

{ #category : 'accessing' }
DeprecationVersionEntry >> version [
	"The major Pharo version, or nil when no version was found"

	^ version
]
