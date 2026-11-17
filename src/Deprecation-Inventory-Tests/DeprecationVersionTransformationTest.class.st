Class {
	#name : 'DeprecationVersionTransformationTest',
	#superclass : 'TestCase',
	#category : 'Deprecation-Inventory-Tests',
	#package : 'Deprecation-Inventory-Tests'
}

{ #category : 'helpers' }
DeprecationVersionTransformationTest >> entryFor: aMethod version: aNumber [

	^ DeprecationVersionEntry method: aMethod version: aNumber source: #package
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testAddsCommitDate [

	| entry source |
	entry := self entryFor: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion version: 13.
	entry date: (DateAndTime year: 2025 month: 3 day: 7).
	source := DeprecationVersionTransformation new sourceWithVersionFor: entry.
	self assert: (source includesSubstring: 'on: ''2025-03-07'' in: #Pharo13 transformWith:')
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testAddsVersionAndUnknownDate [

	| source |
	source := DeprecationVersionTransformation new sourceWithVersionFor:
		          (self entryFor: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion version: 14).
	self assert: source equals: 'deprecatedMessageWithTransformAndNoVersion

	self deprecated: ''This method is part of the DeprecationTest.'' on: ''unknown'' in: #Pharo14 transformWith: ''`@receiver deprecatedMessageWithTransformAndNoVersion'' -> ''`@receiver newMessage'''
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testGeneratesChangesWithoutApplyingThem [

	| method transformation changes |
	method := ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion.
	transformation := DeprecationVersionTransformation entries: { (self entryFor: method version: 14) }.
	changes := transformation generateChanges.
	self assert: changes changes size equals: 1.
	self assert: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion identicalTo: method
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testReplacesUnreadableVersionAndKeepsDate [

	| source |
	source := DeprecationVersionTransformation new sourceWithVersionFor:
		          (self entryFor: SomeClassForCompiledMethodTests >> #deprecatedMethod2 version: 12).
	self assert: (source includesSubstring: 'on: ''date'' in: #Pharo12').
	self deny: (source includesSubstring: 'someversion')
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testResultIsDeprecatedWithVersion [

	| source inventory |
	source := DeprecationVersionTransformation new sourceWithVersionFor:
		          (self entryFor: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion version: 14).
	inventory := DeprecationVersionInventory new.
	self deny: (inventory isDeprecatedWithoutVersion: (OpalCompiler new
		  class: ExampleForDeprecationTest;
		  compile: source))
]

{ #category : 'tests' }
DeprecationVersionTransformationTest >> testSkipsEntriesWithoutVersion [

	| transformation |
	transformation := DeprecationVersionTransformation entries: {
		                  (self entryFor: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion version: 14).
		                  (self entryFor: SomeClassForCompiledMethodTests >> #deprecatedMethod2 version: nil) }.
	self assert: transformation buildTransformations size equals: 1
]
