# Contributing

## Development setup

```sh
git clone https://github.com/baygut/react-native-subject-lift
cd react-native-subject-lift
npm install
```

## Before submitting a PR

- Run `npm run typecheck` — must pass with zero errors
- Run `npm run lint` — must pass
- Run `npm run build` — must succeed
- Add an entry to `CHANGELOG.md` under `[Unreleased]`

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add preferredInteractionTypes prop
fix: handle file:// URI stripping on Android
docs: update README Android setup steps
```

## Releasing (maintainer)

1. Update version in `package.json`
2. Move `[Unreleased]` entries to a versioned section in `CHANGELOG.md`
3. Commit: `chore: release v0.x.0`
4. Create a GitHub Release — the `publish.yml` workflow handles npm publishing automatically
