{
	description = "Nix flake for building a VS Code derivative with Synthwave '84 theme and neon/glow modifications baked in. No extension build or install—just a fully themed VS Code binary.";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		synthwave-vscode = {
			url = "github:robb0wen/synthwave-vscode";
			flake = false;
		};
	};

	outputs = { self, nixpkgs, flake-utils, synthwave-vscode }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				# Unified approach for handling unfree packages
				pkgsAllowUnfree = import nixpkgs {
					inherit system;
					config.allowUnfree = true;
					config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.legacyPackages.${system}.lib.getName pkg) [
						"vscode"
						"vscode-extension-MS-python-python"
						"vscode-extension-ms-vscode-cpptools"
						"vscode-extension-ms-vsliveshare-vsliveshare"
					];
				};
				pkgs = pkgsAllowUnfree;

				# Only include files needed for the build — excludes .git, build artifacts, etc.
				src = pkgs.lib.fileset.toSource {
					root = ./.;
					fileset = pkgs.lib.fileset.unions [
						./patches
						./scripts
						./README.md
						./LICENSE
					];
				};

				# Extension metadata - read version from package.json
				packageJson = builtins.fromJSON (builtins.readFile "${synthwave-vscode}/package.json");
				extensionVersion = packageJson.version;

				# Pre-patched VS Code with Synthwave '84 theme built-in
				synthwave-vscode-baked = pkgs.vscode.overrideAttrs (oldAttrs: {
						pname = "vscode-synthwave84";
						__intentionallyOverridingVersion = true;
						version = "${oldAttrs.version}-vsc-${extensionVersion}-sw84";

						buildInputs = (oldAttrs.buildInputs or []) ++ [ pkgs.jq pkgs.openssl pkgs.patch ];

						installPhase = (oldAttrs.installPhase or "") + (builtins.readFile (pkgs.replaceVars ./scripts/inject-theme.sh {
								SYNTHWAVE_VSCODE = synthwave-vscode;
								PATCHES_DIR = "${self}/patches";
								PATCH_BIN = "${pkgs.patch}/bin/patch";
								JQ_BIN = "${pkgs.jq}/bin/jq";
						}));


					# Fix wrapGAppsHook unbound variable bug - initialize to empty so hook can run normally
					# Hook will respect dontWrapGApps=true and skip wrapping while avoiding [ -z "$var" ] error
				preFixup = ''
					wrapGAppsHookHasRun=""
				'' + (oldAttrs.preFixup or "");

					# Recalculate checksums in postFixup
				postFixup = (oldAttrs.postFixup or "") + (builtins.readFile (pkgs.replaceVars ./scripts/update-checksums.sh {
						JQ_BIN = "${pkgs.jq}/bin/jq";
						OPENSSL_BIN = "${pkgs.openssl}/bin/openssl";
					}));
				});

			in {
				packages = {
					default = synthwave-vscode-baked;
					vscode-synthwave84 = synthwave-vscode-baked;
				};

        devShells.default =
          let devEnv = import ./dev-env.nix { pkgs = pkgs; };
          in pkgs.mkShell {
            inherit (devEnv) buildInputs shellHook;
          };

				apps = {
					default = {
						type = "app";
						program = "${synthwave-vscode-baked}/bin/code";
						meta = {
							description = "Launch VS Code with Synthwave '84 theme baked-in";
							license = nixpkgs.lib.licenses.mit;
						};
					};
				};
			});
}
