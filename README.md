# nix-synthwave-vscode

A Nix flake for building a fully repackaged VS Code with the Synthwave '84 theme (from [robb0wen/synthwave-vscode](https://github.com/robb0wen/synthwave-vscode)) baked directly into the application. This enables a derivative VS Code build with all neon theming and glow effects applied out-of-the-box, without requiring the user to install or patch the extension manually.

## Features

- Repackages upstream VS Code with Synthwave '84 theme and glow modifications pre-injected
- No extension install or user patching required

## Usage

### Quick Start

```bash
# Run directly from GitHub
nix run github:sabrsorensen/nix-synthwave-vscode

# Or build and run locally
nix build
./result/bin/code
```

### Using as a Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-synthwave-vscode.url = "github:sabrsorensen/nix-synthwave-vscode";
  };

  outputs = { self, nixpkgs, nix-synthwave-vscode }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Use in NixOS configuration
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            environment.systemPackages = [
              nix-synthwave-vscode.packages.${system}.default
            ];
          }
        ];
      };

      # Use in Home Manager
      homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home.packages = [
              nix-synthwave-vscode.packages.${system}.vscode-synthwave-84
            ];
          }
        ];
      };

      # Use in development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          nix-synthwave-vscode.packages.${system}.default
        ];
      };
    };
}
```

### Available Packages

- `default` - VS Code with Synthwave '84 theme baked-in
- `vscode-synthwave-84` - Descriptive alias for `default`

### Development

```bash
# Enter development shell
nix develop

# Build the package
nix build

# Run the built package
nix run
```

## Attribution

Based on [robb0wen/synthwave-vscode](https://github.com/robb0wen/synthwave-vscode).
