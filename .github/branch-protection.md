# Main Branch Protection

GitHub Actions can report pass/fail status, but GitHub branch protection is what prevents failing code from landing on `main`.

Enable this in the repository settings:

1. Open `Settings` -> `Branches`.
2. Add a branch protection rule for `main`.
3. Enable `Require a pull request before merging`.
4. Enable `Require status checks to pass before merging`.
5. Select these required checks:
   - `Repository Integrity`
   - `Mobile Quality Gate`
   - `Backend Quality Gate`
   - `Dependency Security Review`
6. Enable `Require branches to be up to date before merging`.
7. Enable `Do not allow bypassing the above settings`.

After this rule is active, a pull request cannot merge into `main` unless the CI checks pass.
