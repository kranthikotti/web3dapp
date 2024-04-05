#! /bin/sh -ea

DIR=$(dirname $0)

NEW_VERSION=$1
if [ -z "$1" ]; then echo "please pass a new version number on the cmdline" && exit 1; fi

PREVIOUS_VERSION=$(sed -E 's/^version = "(.*)"/\1/;t;d' "$DIR/protocol/Cargo.toml")

if ! git diff-index --quiet HEAD --; then
  echo "error: git worktree has uncomitted changes" 1>&2
  exit 1
fi

function update_manifest_version {
  find -name Cargo.toml -not -path "*/target/*" -exec sed -Ei "s/$PREVIOUS_VERSION/$NEW_VERSION/g" "{}" \+
  git commit -am "Bump version to $NEW_VERSION"
}

function warn_if_major_minor_differs {
  new_major_minor=$(echo $NEW_VERSION | cut -d. -f-2)
  readme_version=$(cat $DIR/README.md | sed -E "s/protocol = \{ version = \"(.*)\"/\1/;t;d")

  case $readme_version in
    $new_major_minor*) echo "note: major/minor version is consistent with the README" ;;
    *) echo "error: major or minor version changed, please update the crate version in the README" && exit 1;;
  esac
}

warn_if_major_minor_differs


# TODO: re-enable this cd when impl-box is a default feature
# cargo test --all --all-features
# cargo test --all --no-default-features

if [ "$PREVIOUS_VERSION" != "$NEW_VERSION" ]; then
  update_manifest_version $1
fi

cd protocol-derive
cargo publish

echo "giving crates.io some time to catch up... one moment caller..."
sleep 15 # give crates.io a lot of secs to catch up

cd ../protocol
cargo publish

echo tagging $NEW_VERSION

git tag $NEW_VERSION
git push origin master $NEW_VERSION

