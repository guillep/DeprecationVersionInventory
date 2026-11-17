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
DeprecationVersionInventoryTest >> testVersionContaining [

	| inventory releases |
	inventory := DeprecationVersionInventory repository: (IceRepository registeredRepositoryIncludingPackage: Deprecation package).
	releases := inventory releaseCommits.
	self assert: (inventory versionContaining: (releases at: 13)) equals: 13.
	self assert: (inventory versionContaining: (releases at: 14)) equals: 14.
	self assert: (inventory versionContaining: (releases at: 12) ancestors first) equals: 12.
	self assert: (inventory versionContaining: inventory repository headCommit) equals: SystemVersion current major
]

{ #category : 'tests' }
DeprecationVersionInventoryTest >> testVersionFromDeprecatedPackage [

	| inventory |
	inventory := DeprecationVersionInventory new.
	self assert: (inventory versionFromPackageOf: Object >> #haltOnRead) equals: 14.
	self assert: (inventory versionFromPackageOf: Collection >> #asCommaString) equals: 13.
	self assert: (inventory versionFromPackageOf: Object >> #printString) isNil
]
