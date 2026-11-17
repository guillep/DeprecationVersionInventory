Class {
	#name : 'BaselineOfDeprecationVersionInventory',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfDeprecationVersionInventory',
	#package : 'BaselineOfDeprecationVersionInventory'
}

{ #category : 'baselines' }
BaselineOfDeprecationVersionInventory >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			package: 'Deprecation-Inventory';
			package: 'Deprecation-Inventory-Tests' with: [ spec requires: #( 'Deprecation-Inventory' ) ].
		spec
			group: 'default' with: #( 'Deprecation-Inventory' 'Deprecation-Inventory-Tests' );
			group: 'core' with: #( 'Deprecation-Inventory' ) ]
]
