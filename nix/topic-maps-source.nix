# Topic Maps b2eecffa as its runtime snapshot: the commit's tree without reports/ (2.47 GB), made and verified by
# scripts/topic-maps-snapshot.py; nix/topic-maps-b2eecffa.manifest lets dreyeck/source-snapshot verify it without .git.
# The URL is the intended release location. Until the archive is published there, only a store that already holds
# this hash (added from the local archive) can build the packages that use it; Nix fetches nothing else under it.
{ fetchzip }:
fetchzip {
  url = "https://github.com/RalfBarkow/hyperdoc/releases/download/topic-maps-b2eecffa/topic-maps-b2eecffa-runtime.tar.gz";
  hash = "sha256-Nu7zDGGWj2rYEozoe4sVj6hiDC3HBHGdSvzOBaBcylw=";
}
