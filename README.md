# Installing

Installing this package is easy as copying the repository, then executing

```
make
```

Or

```
make configure
make install
```

## Caveats

Currently, on nixpkgs-22.05-darwin, golint is marked broken. As such, you may need to execute

```
make ALLOW_BROKEN=1
```

to install the environment.

If you're on Linux, you might be SOL. Some package in the home-manager dependencies relies on python-openssl, which is marked broken. Using the above hack doesn't work either since tests will be run on the python-openssl package that fail.
