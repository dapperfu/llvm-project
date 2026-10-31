"""Compare llvm-mc against the NXP GNU assembler probe results.

Each probe line is "OK  | <instruction> | <bytes>  <disassembly>" or
"ERR | <instruction> | <message> ...".  For OK lines the instruction is
assembled with llvm-mc into an object and the .text bytes must equal the GNU
bytes; for ERR lines llvm-mc must reject the instruction.  Known, documented
differences are listed with --expect-diff (instruction text, repeatable).
"""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

import click


def assemble(bin_dir: Path, args: list[str], line: str) -> tuple[bool, bytes, str]:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "t.s"
        obj = Path(tmp) / "t.o"
        raw = Path(tmp) / "t.bin"
        src.write_text(f"\t.text\nx:\n\t{line}\n")
        mc = subprocess.run(
            [bin_dir / "llvm-mc", "-triple=powerpc-unknown-eabi", *args, "-filetype=obj",
             str(src), "-o", str(obj)],
            capture_output=True, text=True)
        if mc.returncode != 0:
            return False, b"", mc.stderr.strip().splitlines()[0] if mc.stderr else ""
        subprocess.run([bin_dir / "llvm-objcopy", "-O", "binary", "--only-section=.text",
                        str(obj), str(raw)], check=True)
        return True, raw.read_bytes(), ""


@click.command()
@click.option("--bin-dir", type=click.Path(exists=True, path_type=Path), required=True)
@click.option("--probe", "probes", type=click.Path(exists=True, path_type=Path), multiple=True,
              required=True)
@click.option("--mattr", default="+vle")
@click.option("--mcpu", default="e200z4")
@click.option("--expect-diff", "expected", multiple=True)
def main(bin_dir: Path, probes: tuple[Path, ...], mattr: str, mcpu: str,
         expected: tuple[str, ...]) -> None:
    args = [f"-mcpu={mcpu}", f"-mattr={mattr}"]
    total = failures = 0
    for probe in probes:
        for raw_line in probe.read_text().splitlines():
            parts = [p.strip() for p in raw_line.split("|")]
            if len(parts) < 3:
                continue
            status, inst = parts[0], parts[1]
            total += 1
            ok, data, err = assemble(bin_dir, args, inst)
            if status == "OK":
                gnu = []
                for token in parts[2].split():
                    if len(token) != 2 or any(c not in "0123456789abcdef" for c in token):
                        break
                    gnu.append(token)
                if not gnu:
                    continue
                want = bytes(int(b, 16) for b in gnu)
                good = ok and data == want
                detail = f"llvm: {data.hex(' ') if ok else err} gnu: {want.hex(' ')}"
            else:
                good = not ok
                detail = f"llvm accepted: {data.hex(' ')}; gnu: {parts[2]}"
            if good == (inst in expected):
                failures += 1
                tag = "UNEXPECTED-PASS" if good else "MISMATCH"
                click.echo(f"{tag} {probe.name}: {inst}: {detail}")
    click.echo(f"{total} lines, {failures} unexpected results")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
