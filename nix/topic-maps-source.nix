# Topic Maps 88994c1b as its runtime snapshot: the commit's tree without reports/ (2.47 GB), made and verified by
# scripts/topic-maps-snapshot.py; nix/topic-maps-88994c1b.manifest lets dreyeck/source-snapshot verify it without .git.
# 88994c1b is 6162ed68 plus the indexed Association merge search (Task 1E, independently reviewed). The 6162ed68 and b2eecffa
# snapshots and manifests (hashes sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M= for 6162ed68) stay in the repository as history.
#
# The archive is in this repository (nix/topic-maps-88994c1b-runtime.tar.gz, 1,062,834 octets, SHA-256
# 6fe74dc31e5291b03d440cfbeaf41c38d021225f36ce7fb96afcbcd632006cdd), so no builder fetches anything and no release has to be
# published. The derivation is fixed-output: Nix itself refuses an archive whose unpacked tree does not have the NAR hash below,
# and its store path is the same one a fetchzip of the same tree would give. The Lisp verifier then checks the tree against the
# Git objects in nix/topic-maps-88994c1b.manifest at every start. scripts/topic-maps-snapshot.py create reproduces the archive
# and the manifest byte for byte from a Topic Maps checkout at the commit.
{ runCommand, gnutar, gzip }:
runCommand "source"
  {
    nativeBuildInputs = [ gnutar gzip ];
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-5h3t+4tb0J49Zt9bWtu3ZCX46OjDVmZOWlfy/pu7h40=";
  }
  ''
    mkdir "$out"
    # The archive has one top-level directory, topic-maps-88994c1b/, which is not part of the tree.
    tar -xzf ${./topic-maps-88994c1b-runtime.tar.gz} -C "$out" --strip-components=1 --no-same-owner
  ''
