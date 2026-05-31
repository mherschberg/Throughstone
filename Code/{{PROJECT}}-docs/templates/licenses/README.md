# License templates

Source text for the license that `init.sh` stamps into your project repo(s). Each file uses
two placeholders that `init.sh` fills in: `{{YEAR}}` and `{{HOLDER}}` (the copyright holder).

`init.sh` first asks whether the project is **open source** or **private/proprietary**.
Open source then picks one of the three permissive licenses; private stamps the proprietary
notice. Either way the filled text is written to `LICENSE` in each repo.

| File | License | When `init.sh` uses it |
|------|---------|------------------------|
| `MIT.txt` | MIT | Open source → MIT. Permissive, simplest; a good default. |
| `BSD-3-Clause.txt` | BSD 3-Clause | Open source → BSD-3. Permissive, plus a name-endorsement protection clause. |
| `Apache-2.0.txt` | Apache License 2.0 | Open source → Apache. Permissive, with an explicit patent grant; common for larger/commercial OSS. |
| `Proprietary.txt` | Proprietary / all rights reserved | Private/proprietary projects. An explicit "all rights reserved" notice. |

To use a different license, drop its text here as `<name>.txt` (with the same placeholders)
and add a branch in `init.sh`, or just add the `LICENSE` to your repo by hand.
