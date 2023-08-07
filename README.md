# Building
From the root directory of this project execute:
```
nix build .#dist
```
The result directory will be a symlink to the dist directory in the Nix store.

# Deploying

From the root directory of this project execute:
```
nix run .#srht-deploy
```
Will query you for the password used to encrypt the sorucehut deployment secret, and on valid input deploy the `dist` directory to sourcehut pages.
