# purescript-node-fs-temporary
Temporary file and directory support. Purescript implementation for UnliftIO.Temporary, which was strongly inspired by/stolen from the https://github.com/feuerbach/temporary package.

## Usage without purs-nix

To use this package you will need a patched version of `purescript-node-os` until this [PR](https://github.com/Thimoteus/purescript-node-os/pull/5) gets merged.

repository: `https://github.com/marijanp/purescript-node-os.git`

rev = `d0d672eb42007b544a3148988cf58e9806e70266`

## Usage with purs-nix

In your `flake.nix`:

```nix
let
  inherit (inputs.purescript-node-fs-temporary.packages.x86_64-linux) node-fs-temporary;

  purs-nix = inputs.purs-nix {
    inherit system;
    overlays = [
      node-fs-temporary.overlay
    ];
  };
  
  my-package = purs-nix.build {
    name = "my-package";
    src.path = ./.;
    info = {
      version = "0.0.1";
      dependencies = [
        node-fs-temporary       # important: refer to the derivation not the string
      ];
    };
  };
in
{
  packages.x86_64-linux.my-package = my-package;
}
```

## Run unit-tests

To run the unit-tests:
```
nix run .#checks.x86_64-linux.node-fs-temporary
```

## Develop

### Enter the development environment

```
nix develop
```

or

```
nix develop .#default
```

### Compile and run tests automatically on every change (recommended)

```
feedback -- purs-nix test
```

### Compile the code manually

```
purs-nix compile
```

### Compile and test your changes manually

```
purs-nix test
```

