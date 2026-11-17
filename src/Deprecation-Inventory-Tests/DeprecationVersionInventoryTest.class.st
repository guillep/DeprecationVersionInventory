Class {
	#name : 'DeprecationVersionInventoryTest',
	#superclass : 'TestCase',
	#category : 'Deprecation-Inventory-Tests',
	#package : 'Deprecation-Inventory-Tests'
}

{ #category : 'tests' }
DeprecationVersionInventoryTest >> testDeprecationsWithoutVersion [

	| inventory |
	inventory := DeprecationVersionInventory new.
	self assert: (inventory isDeprecatedWithoutVersion: ExampleForDeprecationTest >> #deprecatedMessageWithTransformAndNoVersion).
	self deny: (inventory isDeprecatedWithoutVersion: ExampleForDeprecationTest >> #deprecatedMessageWithTransform).
	self deny: (inventory isDeprecatedWithoutVersion: Object >> #haltOnRead).
	self assert: (inventory isDeprecatedWithoutVersion: SomeClassForCompiledMethodTests >> #deprecatedMethod2).
	self deny: (inventory isDeprecatedWithoutVersion: CompiledMethod >> #isDeprecated)
]

{ #category : 'tests' }
DeprecationVersionInventoryTest >> testOnlyMethodsOfTheRepository [

	| inventory |
	inventory := DeprecationVersionInventory repository: (IceRepository registeredRepositoryIncludingPackage: Deprecation package).
	self assert: (inventory isInRepository: Object >> #haltOnRead).
	self deny: (inventory isInRepository: DeprecationVersionInventory >> #entries).
	self assert: (DeprecationVersionInventory new isInRepository: DeprecationVersionInventory >> #entries)
]

{ #category : 'tests' }
DeprecationVersionInventoryTest >> testVersionDevelopedAt [

	| inventory |
	inventory := DeprecationVersionInventory new.
	inventory releaseDates: {
		(12 -> (DateAndTime year: 2024 month: 4 day: 29)).
		(13 -> (DateAndTime year: 2025 month: 5 day: 15)) } asDictionary.
	self assert: (inventory versionDevelopedAt: (DateAndTime year: 2024 month: 1 day: 1)) equals: 12.
	self assert: (inventory versionDevelopedAt: (DateAndTime year: 2024 month: 6 day: 1)) equals: 13.
	self assert: (inventory versionDevelopedAt: (DateAndTime year: 2025 month: 6 day: 1)) equals: SystemVersion current major
]

{ #category : 'tests' }
DeprecationVersionInventoryTest >> testVersionFromDeprecatedPackage [

	| inventory |
	inventory := DeprecationVersionInventory new.
	self assert: (inventory versionFromPackageOf: Object >> #haltOnRead) equals: 14.
	self assert: (inventory versionFromPackageOf: Collection >> #asCommaString) equals: 13.
	self assert: (inventory versionFromPackageOf: Object >> #printString) isNil
]
