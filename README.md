# Work Nix Flake

Flake file should be located in `/etc/nix-darwin`.

After editing file, do rebuild to apply changes (will need to enter password)
```shell
darwin-rebuild switch --flake .#work
```

To update packages, ensure latest flake file is committed then run
```shell
nix flake update
```
Then commit changes if everything looks good.
