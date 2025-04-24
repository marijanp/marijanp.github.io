{
  runCommand,
  soupault,
  tailwindcss_4,
  pandoc,
  nodejs,
  npmlock2nix,
  lib,
}:
let
  NODE_PATH = "${
    npmlock2nix.v2.node_modules {
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./package.json
          ./package-lock.json
        ];
      };
      inherit nodejs;
    }
  }/node_modules";
in
runCommand "dist"
  {
    LANG = "en_US.UTF-8";
    nativeBuildInputs = [
      soupault
      tailwindcss_4
      pandoc
    ];
    inherit NODE_PATH;
  }
  ''
    set -euo pipefail
    cp -r ${./site} site
    cp -r ${./templates} templates
    cp -r ${./plugins} plugins
    echo "Running soupault ..."
    soupault --debug --config ${./soupault.toml}

    # The tailwind CLI doesn't check the NODE_PATH environment variable,
    # it expects a node_modules folder
    cp -r ${NODE_PATH} build/css/node_modules

    echo "Running tailwind ..."
    tailwindcss -i build/css/style.in.css -o build/css/style.css
    rm build/css/style.in.css

    chmod -R +w build/css/node_modules
    rm -r build/css/node_modules

    echo "Running syntax highlighter ..."
    tmp=$(mktemp)
    echo '$highlighting-css$' > "$tmp"
    echo '`test`{.c}' | pandoc --highlight-style=zenburn --template="$tmp" > build/css/syntax.css

    mkdir -p $out
    cp -r build/* $out/
  ''
