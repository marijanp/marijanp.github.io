{
  runCommand,
  soupault,
  nodePackages,
  pandoc,
  nodejs,
  npmlock2nix,
  lib,
}:

runCommand "dist"
  {
    LANG = "en_US.UTF-8";
    nativeBuildInputs = [
      nodePackages.tailwindcss
      pandoc
    ];
    NODE_PATH = "${
      npmlock2nix.v2.node_modules {
        src = ./.;
        inherit nodejs;
      }
    }/node_modules";
  }
  ''
    set -euo pipefail
    cp -r ${./site} site
    cp -r ${./templates} templates
    cp -r ${./plugins} plugins
    ${lib.getExe soupault} --debug --config ${./soupault.toml}

    chmod +w build/css/style.css
    tailwindcss -c ${./tailwind.config.js} -i build/css/style.css -o build/css/style.css
    chmod -w build/css/style.css

    tmp=$(mktemp)
    echo '$highlighting-css$' > "$tmp"
    echo '`test`{.c}' | pandoc --highlight-style=zenburn --template="$tmp" > build/css/syntax.css

    mkdir -p $out
    cp -r build/* $out/
  ''
