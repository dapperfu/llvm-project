"""Extract VLEPEM Rev. 0 Table B-2 (VLE instruction set sorted by mnemonic).

The table lists every instruction available in VLE mode, including the Book E
instructions that keep their 32-bit encoding.  Each row becomes one inventory
record with its form, opcode, mode dependency, privilege, category and the
PDF page it was read from, so later milestones can cite it.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import click
import yaml

ROW_RE = re.compile(
    r"^\s*(?P<form>[A-Z0-9]+)\s+(?P<opcode>[0-9A-F]{4}(?:----|[0-9A-F]{4}))\s+"
    r"(?:(?P<mode>SR|CT|32|64)\s+)?(?:(?P<priv>[POM])\s+)?"
    r"(?P<cat>[A-Z][A-Za-z0-9.]*)\s+(?P<mnem>[a-z_][a-z0-9_.\[\]]*)\s+(?P<desc>\S.*)$"
)
FOOTER_RE = re.compile(r"^\s*B-(?P<page>\d+)\s*$|Freescale Semiconductor\s+B-(?P<page2>\d+)\s*$")
TABLE_START = "Table B-2. VLE Instruction Set Sorted by Mnemonic"
TABLE_END = "B.2"


def pdf_text(pdf: Path) -> list[str]:
    """Return the layout-preserving text of a PDF as lines."""
    out = subprocess.run(
        ["pdftotext", "-layout", str(pdf), "-"], check=True, capture_output=True, text=True
    )
    return out.stdout.splitlines()


def classify(mnemonic: str, opcode: str) -> tuple[str, int]:
    """Return (mode, width) for a Table B-2 row.

    16-bit encodings are printed as four hex digits followed by "----".
    """
    width = 16 if opcode.endswith("----") else 32
    if mnemonic.startswith(("se_", "e_")):
        return "vle", width
    return "shared", width


def extract(lines: list[str]) -> list[dict]:
    """Parse the Table B-2 rows from pdftotext output."""
    records: list[dict] = []
    in_table = False
    page = "B-1"
    for line in lines:
        if TABLE_START in line:
            in_table = True
            continue
        if in_table and line.strip().startswith(TABLE_END) and "Sorted by Opcode" in line:
            break
        if not in_table:
            continue
        footer = FOOTER_RE.search(line)
        if footer:
            page = "B-" + (footer.group("page") or footer.group("page2"))
            continue
        m = ROW_RE.match(line)
        if not m:
            continue
        mnemonic = m.group("mnem")
        mode, width = classify(mnemonic, m.group("opcode"))
        records.append(
            {
                "mnemonic": mnemonic,
                "form": m.group("form"),
                "opcode_hex": "0x" + m.group("opcode").rstrip("-"),
                "width": width,
                "mode": mode,
                "mode_dependency": m.group("mode"),
                "privilege": m.group("priv") or "none",
                "category": m.group("cat"),
                "description": m.group("desc").strip(),
                "sources": [{"doc": "VLEPEM Rev. 0", "table": "B-2", "page": page}],
            }
        )
    return records


@click.command()
@click.option(
    "--pdf",
    "pdf",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    required=True,
    help="Path to VLEPEM.pdf (VLEPEM Rev. 0, 07/2007).",
)
@click.option(
    "--output",
    type=click.Path(dir_okay=False, path_type=Path),
    required=True,
    help="YAML file to write.",
)
def main(pdf: Path, output: Path) -> None:
    """Write VLEPEM Table B-2 as YAML records."""
    records = extract(pdf_text(pdf))
    if not records:
        raise click.ClickException("no Table B-2 rows found; is this VLEPEM Rev. 0?")
    output.write_text(yaml.safe_dump(records, sort_keys=False, width=100))
    vle = sum(1 for r in records if r["mode"] == "vle")
    click.echo(f"{len(records)} rows ({vle} VLE-specific, {len(records) - vle} shared)")


if __name__ == "__main__":
    main()
