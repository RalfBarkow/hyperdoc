# Only after asset-http succeeds, in the same set -e Bash session.
: "${APPROVE_ASSET_SWITCH:?Set explicitly after reviewing the verification}"
test "$APPROVE_ASSET_SWITCH" = "$MECH_REV"
# No concurrent publisher; confirm the active selection has not changed.
previous_link=$(cat "$receipt/previous-link")
if test -n "$previous_link"; then
  test "$(readlink "$target")" = "$previous_link"
else
  test ! -e "$target" && test ! -L "$target"
fi
if test "$previous_link" = "hyperdoc-mech-versions/$MECH_REV"; then
  echo "Already selected; active symlink unchanged"
else
  next_dir=$(mktemp -d "$wiki_assets_dir/.mech-switch.XXXXXXXX")
  ln -s "hyperdoc-mech-versions/$MECH_REV" "$next_dir/link"
  mv -Tf "$next_dir/link" "$target"
  rmdir "$next_dir"
fi
readlink "$target" > "$receipt/activated-link"
verify_host "$asset_origin/assets/hyperdoc-mech"
# No wiki.service or hyperdoc.service restart for this asset-only switch.
