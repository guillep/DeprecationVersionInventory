# DeprecationVersionInventory

Find out **in which Pharo version each deprecation was introduced**, for the deprecations that do not say so.

[PHEP-0004](https://github.com/pharo-project/pheps/blob/main/phep-0004.md) asks every deprecation to state the Pharo version that introduced it, because that version decides two things:

- how long the deprecated API must keep working: **4 versions** for kernel packages, **2 versions** for the rest, counting the version that deprecates it;
- when automatic rewriting of callers may start: only in the **last version** of that compatibility period.

A deprecation without a version cannot follow either rule. Pharo images hold hundreds of them:

```smalltalk
self deprecated: 'Use #newMessage instead'
	transformWith: '`@rcv oldMessage' -> '`@rcv newMessage'.
```

This tool lists them and finds the missing version, so it can be added:

```smalltalk
self deprecated: 'Use #newMessage instead'
	on: '1/1/2026'
	in: #Pharo14
	transformWith: '`@rcv oldMessage' -> '`@rcv newMessage'.
```

## How the version is found

For every method that sends a deprecation message to `self` without a readable `in:` version:

1. **Package.** A method in a `DeprecatedN` package (`Deprecated14`, `Deprecated13-Kernel`) was deprecated in Pharo N.
2. **History.** Otherwise, the git history of the method (through Iceberg, in the method's own repository) gives the oldest commit sending `deprecated:`. The version is the first Pharo release after that commit, read from the `vN.0.0` tags of the Pharo repository. A commit newer than every release maps to the version under development.
3. **Unknown.** Methods with no repository or no such commit are reported apart, for a human to decide.

Backports are ignored: a deprecation is attributed to the version under development when it was committed.

## Usage

```smalltalk
inventory := DeprecationVersionInventory repository:
	(IceRepository registeredRepositoryIncludingPackage: Deprecation package).

inventory entries.
"an Array(Object>>#deepCopy -> Pharo14 (history) ...)"

(inventory entries groupedBy: [ :each | each source ]).
"#package, #history and #unknown"
```

Each `DeprecationVersionEntry` answers its `method`, its `version` (a major version number, or `nil`) and its `source`.

Reading the history walks the whole git log once per method, which takes several seconds each on the Pharo repository. Run large inventories in a background process.

## Installation

```smalltalk
Metacello new
	baseline: 'DeprecationVersionInventory';
	repository: 'github://guillep/DeprecationVersionInventory:master/src';
	load.
```

It needs a Pharo image where `Deprecation >> #deprecationMajorVersion` exists (it reads versions such as `#Pharo14` or `'pharo13'`), and Iceberg with the image's repositories registered.

## License

MIT
