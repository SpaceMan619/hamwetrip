# HamweTrip: simple team workflow

`main` now contains the one shared Flutter project. We are **not** creating
separate apps or separate project folders. Everything happens inside
`hamwetrip/`.

## Start once

```bash
git pull origin main
cd hamwetrip
flutter pub get
flutter run
```

## Every time you work on a feature

1. Pull the latest `main`.
2. Create a small branch for one task. Examples:
   `frontend/shakira-voting-ui`, `frontend/rajveer-home-ui`,
   `backend/kamanzi-auth`, or `backend/aime-trip-repository`.
3. Make only the changes for that task.
4. Before pushing, run:

   ```bash
   dart format lib test
   flutter analyze
   flutter test
   ```

5. Push your branch and open a pull request (or send the branch link to the
   team member handling the merge).
6. Merge only after the work runs and another person has looked at it.

## Where work goes

| Work | Folder |
| --- | --- |
| Screens, feature widgets, and feature state | `hamwetrip/lib/features/<feature>/` |
| Shared reusable UI/helpers | `hamwetrip/lib/core/` (create when needed) |
| Models and repository/API implementations | `hamwetrip/lib/data/` |
| Firebase/backend setup and integration helpers | `hamwetrip/lib/backend/` |

Rajveer and Shakira own the frontend feature screens. Kamanzi and Aime own the
data, backend integration, and testing. If a screen needs data, agree on the
model/repository interface first; then frontend can build against it while
backend wires the real service.

## Keep it simple

- One branch = one focused task.
- Do not push unfinished experiments directly to `main`.
- Do not move another person's feature folder without telling them.
- Keep keys, passwords, and service credentials out of Git.
- Ask in the group before adding a package that changes the whole app.

This base is intentionally plain. The team can now add the real HamweTrip
design and features in small, mergeable pieces.
