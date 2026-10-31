"""Compare LLVM's VLE disassembly of every first halfword with the M1 map.

The M1 probe (P12) disassembled, with NXP objdump, 65,536 samples of the form
[h][se_nop][se_nop][se_nop] and recorded whether each h starts a 16-bit, a
32-bit or no valid instruction (probes/out/p12-length-map.txt).  This tool
builds the same samples in a VLE section, disassembles them with llvm-objdump
and reports:

  * length mismatches (both decode h, with different lengths): must be none;
  * halfwords only GNU decodes, grouped by GNU mnemonic (instructions LLVM does
    not implement yet);
  * halfwords only LLVM decodes, grouped by LLVM mnemonic.

Usage:
  python vle_length_sweep.py --llvm-bin build/bin \\
      --map ../probes/out/p12-length-map.txt [--mcpu e200z4] [--mattr +spe]
"""

from __future__ import annotations

import collections
import re
import subprocess
import tempfile
from pathlib import Path

import click

LINE = re.compile(r"\s+([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)")


def load_map(path: Path) -> dict[int, tuple[str, str]]:
    result = {}
    for line in path.read_text().splitlines():
        if line.startswith("#"):
            continue
        h, kind, text = (line.split(" ", 2) + [""])[:3]
        result[int(h, 16)] = (kind, text)
    return result


def llvm_map(llvm_bin: Path, mcpu: str, mattr: str) -> dict[int, tuple[str, str]]:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "sweep.s"
        obj = Path(tmp) / "sweep.o"
        with src.open("w") as f:
            f.write('\t.section .text,"axv"\n')
            for h in range(0x10000):
                f.write(f"\t.short 0x{h:04x}, 0x4400, 0x4400, 0x4400\n")
        subprocess.run([llvm_bin / "llvm-mc", "-triple=powerpc-unknown-eabi", f"-mcpu={mcpu}",
                        "-filetype=obj", str(src), "-o", str(obj)], check=True)
        args = [llvm_bin / "llvm-objdump", "-d", f"--mcpu={mcpu}"]
        if mattr:
            args.append(f"--mattr={mattr}")
        out = subprocess.run([*args, str(obj)], capture_output=True, text=True, check=True).stdout
    starts = {}
    for line in out.splitlines():
        m = LINE.match(line)
        if m:
            starts[int(m.group(1), 16)] = (m.group(2).split(), m.group(3).strip())
    result = {}
    for h in range(0x10000):
        raw, text = starts.get(h * 8, ([], ""))
        if not text or text.startswith("<unknown>"):
            result[h] = ("invalid", text)
        else:
            result[h] = ("16" if len(raw) == 2 else "32", text)
    return result


@click.command()
@click.option("--llvm-bin", type=click.Path(exists=True, path_type=Path), required=True)
@click.option("--map", "map_path", type=click.Path(exists=True, path_type=Path), required=True)
@click.option("--mcpu", default="e200z4")
@click.option("--mattr", default="")
def main(llvm_bin: Path, map_path: Path, mcpu: str, mattr: str) -> None:
    gnu = load_map(map_path)
    llvm = llvm_map(llvm_bin, mcpu, mattr)
    length = []
    gnu_only: collections.Counter[str] = collections.Counter()
    llvm_only: collections.Counter[str] = collections.Counter()
    for h in range(0x10000):
        gk, gt = gnu[h]
        lk, lt = llvm[h]
        if gk != "invalid" and lk != "invalid" and gk != lk:
            length.append(f"{h:04x}: gnu {gk} {gt!r}, llvm {lk} {lt!r}")
        elif gk != "invalid" and lk == "invalid":
            gnu_only[gt.split()[0]] += 1
        elif gk == "invalid" and lk != "invalid":
            llvm_only[lt.split()[0]] += 1
    click.echo(f"length mismatches: {len(length)}")
    for item in length[:50]:
        click.echo(f"  {item}")
    click.echo(f"decoded only by GNU: {sum(gnu_only.values())}")
    for mnemonic, count in gnu_only.most_common():
        click.echo(f"  {mnemonic} {count}")
    click.echo(f"decoded only by LLVM: {sum(llvm_only.values())}")
    for mnemonic, count in llvm_only.most_common():
        click.echo(f"  {mnemonic} {count}")
    raise SystemExit(1 if length else 0)


if __name__ == "__main__":
    main()
