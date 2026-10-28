# Topic Maps 88994c1b as its runtime snapshot: the commit's tree without reports/ (2.47 GB), made and verified by
# scripts/topic-maps-snapshot.py; nix/topic-maps-88994c1b.manifest lets dreyeck/source-snapshot verify it without .git.
# 88994c1b is 6162ed68 plus the indexed Association merge search (Task 1E, independently reviewed). The 6162ed68 and b2eecffa
# snapshots and manifests (hashes sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M= for 6162ed68) stay in the repository as history.
# The URL is the intended release location. Until the archive is published there, only a store that already holds
# this hash (added from the local archive) can build the packages that use it; Nix fetches nothing else under it.
{ fetchzip }:
fetchzip {
  url = "https://github.com/RalfBarkow/hyperdoc/releases/download/topic-maps-88994c1b/topic-maps-88994c1b-runtime.tar.gz";
  hash = "sha256-5h3t+4tb0J49Zt9bWtu3ZCX46OjDVmZOWlfy/pu7h40=";
}
