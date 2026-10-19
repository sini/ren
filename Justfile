# Verifies both implementations and their shared fleet template.
# Each impl runs in its own shell.nix (own pins).

ci: twin stimpy ren

# both impls ship the same templates/fleet; only the dependency differs
twin:
    diff -r --exclude=flake.nix --exclude=flake.lock ren/templates/fleet stimpy/templates/fleet

stimpy: (impl "stimpy") (e2e "stimpy")

ren: (impl "ren") (e2e "ren")

impl name:
    cd {{name}} && nix-shell ./shell.nix --run 'just ci'

e2e name:
    cd {{name}} && nix-shell ./shell.nix --run 'just e2e'
