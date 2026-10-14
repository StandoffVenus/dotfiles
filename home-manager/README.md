# macOS setup

1. Install [Determinate Nix](https://docs.determinate.systems/determinate-nix/):

   ```sh
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```

2. Check this repository out as `~/.config` (the `hm` function expects
   `~/.config/home-manager`):

   ```sh
   cd ~/.config
   git init -b macos
   git remote add origin git@github.com:StandoffVenus/dotfiles.git
   git fetch origin macos
   git checkout macos
   ```

3. Activate the configuration. `-b backup` moves aside any existing dotfiles
   Home Manager would otherwise refuse to overwrite:

   ```sh
   nix run home-manager/release-26.05 -- switch -b backup \
     --flake ~/.config/home-manager#mule
   ```

Afterwards, use `hm`:

- `hm switch`: apply changes to the configuration
- `hm update [input…]`: bump `flake.lock`
- `hm upgrade`: both of the above
- `hm edit`: open `flake.nix`

Nix itself is updated by Determinate: `sudo determinate-nixd upgrade`.

Docker Desktop is not packaged; `colima start` provides the daemon for the
`docker` CLI instead.
