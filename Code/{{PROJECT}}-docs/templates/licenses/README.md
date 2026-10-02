# License templates

Source text for the open-source license that `init.sh` stamps into your project repo(s).
Each file uses two placeholders that `init.sh` fills in: `{{YEAR}}` and `{{HOLDER}}` (the
copyright holder).

`init.sh` first asks whether the project is **open source** or **proprietary**.
Open source then picks one of the three permissive licenses and writes the filled text to
`LICENSE` in the bootstrap repos. The docs hub's copy is canonical. When an application-code
repo is added, its licence files follow `runbooks/register-repo.md` step 3. The selection is also
recorded as a validated token in `.throughstone/project-license`; `scripts/apply-project-license.sh`
fails if an open-source selection's canonical `LICENSE` is missing. A proprietary project records
`Proprietary` and gets no project `LICENSE` file.

| File | License | When `init.sh` uses it |
|------|---------|------------------------|
| `MIT.txt` | MIT | Open source → MIT. Permissive, simplest; a good default. |
| `BSD-3-Clause.txt` | BSD 3-Clause | Open source → BSD-3. Permissive, plus a name-endorsement protection clause. |
| `Apache-2.0.txt` | Apache License 2.0 | Open source → Apache. Permissive, with an explicit patent grant; common for larger/commercial OSS. |

To use a different license, add the `LICENSE` to your repo by hand.
