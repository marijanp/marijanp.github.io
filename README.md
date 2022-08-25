# Building the site
From the root directory of this project execute:
```
nix run .#"marijanp-github-io:exe:site" -- build
```
This will build the website and place the result into the `docs` directory, which will be deployed by GitHub Actions.