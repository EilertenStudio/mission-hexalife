#!/usr/bin/env bash
set -euo pipefail

: "${FUNKEY_SOURCE_ROOT:?Esegui questo script tramite Mise}"
: "${FUNKEY_SCENE_SOURCE:?Esegui questo script tramite Mise}"

clone_pinned() {
  local name="$1"
  local repository="$2"
  local tag="$3"
  local expected_commit="$4"
  local destination="$FUNKEY_SOURCE_ROOT/$name"

  if [[ ! -e "$destination" ]]; then
    mkdir -p "$(dirname "$destination")"
    git clone --quiet --depth 1 --branch "$tag" "$repository" "$destination"
  elif [[ ! -d "$destination/.git" ]]; then
    printf 'Esiste già %s ma non è un checkout Git; non lo modifico.\n' "$destination" >&2
    return 1
  elif [[ -n "$(git -C "$destination" status --porcelain --untracked-files=no)" ]]; then
    printf 'Il checkout %s contiene modifiche locali; non lo sovrascrivo.\n' "$destination" >&2
    return 1
  else
    local current_commit
    current_commit="$(git -C "$destination" rev-parse HEAD)"
    if [[ "$current_commit" != "$expected_commit" ]]; then
      git -C "$destination" fetch --quiet --depth 1 origin "refs/tags/$tag:refs/tags/$tag"
      local tag_commit
      tag_commit="$(git -C "$destination" rev-parse "$tag^{commit}")"
      if [[ "$tag_commit" != "$expected_commit" ]]; then
        printf 'Il tag upstream %s/%s è cambiato: atteso %s, trovato %s.\n' "$name" "$tag" "$expected_commit" "$tag_commit" >&2
        return 1
      fi
      git -C "$destination" checkout --quiet --detach "$expected_commit"
    fi
  fi

  local installed_commit
  installed_commit="$(git -C "$destination" rev-parse HEAD)"
  if [[ "$installed_commit" != "$expected_commit" ]]; then
    printf 'Il checkout %s non corrisponde al commit fissato %s.\n' "$name" "$expected_commit" >&2
    return 1
  fi
}

clone_pinned funkey https://github.com/isene/funkey.git v0.8.1 0f6062dc5fe25e50b50fea1f79f75c9e73699471
clone_pinned crust https://github.com/isene/crust.git v0.1.62 88b84db41c22de47868884a74dac879cb63abc5a
clone_pinned glow https://github.com/isene/glow.git v0.1.49 eb3f20e9f387174359db99a1c9ca9ce9dba215ee

wrapper="$FUNKEY_SOURCE_ROOT/funkey/examples/hexalife_cryogenic_awakening.rs"
wrapper_tmp="$wrapper.tmp"
printf 'include!(env!("FUNKEY_SCENE_SOURCE"));\n' > "$wrapper_tmp"
if cmp -s "$wrapper_tmp" "$wrapper" 2>/dev/null; then
  rm "$wrapper_tmp"
else
  mv "$wrapper_tmp" "$wrapper"
fi
