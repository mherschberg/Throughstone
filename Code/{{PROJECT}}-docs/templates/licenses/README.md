# License templates

Source text for the open-source license that `init.sh` stamps into your project repo(s).
Each file uses two placeholders that `init.sh` fills in: `{{YEAR}}` and `{{HOLDER}}` (the
copyright holder).

`init.sh` first asks whether the project is **open source** or **private/proprietary**.
Open source then picks one of the three permissive licenses and writes the filled text to
`LICENSE` in the bootstrap repos. The docs hub's copy is canonical and is copied unchanged
into each application-code repo when that repo is created later. The selection is also recorded
as a validated token in `.throughstone/project-license`; the propagation helper fails if an
open-source selection's canonical `LICENSE` is missing. Private projects record `Proprietary`
and do not get a project `LICENSE` file.

| File | License | When `init.sh` uses it |
|------|---------|------------------------|
| `MIT.txt` | MIT | Open source → MIT. Permissive, simplest; a good default. |
| `BSD-3-Clause.txt` | BSD 3-Clause | Open source → BSD-3. Permissive, plus a name-endorsement protection clause. |
| `Apache-2.0.txt` | Apache License 2.0 | Open source → Apache. Permissive, with an explicit patent grant; common for larger/commercial OSS. |

To use a different license, drop its text here as `<name>.txt` (with the same placeholders)
and add a branch in `init.sh`, or just add the `LICENSE` to your repo by hand.
