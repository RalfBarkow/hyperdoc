# Topic Maps 6162ed68 as its runtime snapshot: the commit's tree without reports/ (2.47 GB), made and verified by
# scripts/topic-maps-snapshot.py; nix/topic-maps-6162ed68.manifest lets dreyeck/source-snapshot verify it without .git.
# 6162ed68 is b2eecffa plus the indexed Topic merge search (Task 1C, independently reviewed). The b2eecffa snapshot and
# manifest (hash sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M=) stay in the repository as history.
# The URL is the intended release location. Until the archive is published there, only a store that already holds
# this hash (added from the local archive) can build the packages that use it; Nix fetches nothing else under it.
{ fetchzip }:
fetchzip {
  url = "https://github.com/RalfBarkow/hyperdoc/releases/download/topic-maps-6162ed68/topic-maps-6162ed68-runtime.tar.gz";
  hash = "sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M=";
}
