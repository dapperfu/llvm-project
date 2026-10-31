"""Generate llvm-mc CHECK lines whose encodings come from the NXP assembler.

Input: a test source whose instruction lines are assembled one at a time.
For each instruction the NXP GNU assembler supplies the reference bytes and
llvm-mc the printed form; the tool fails if llvm-mc encodes differently.
Lines starting with "#" and blank lines are copied unchanged, RUN lines
included, so the input is the test file without its CHECK lines.

Usage:
  python gen_mc_test.py --nxp-bin S32DS/.../bin --llvm-bin build/bin \\
      --gnu-args "-mvle -me200z4" --llvm-args "-mcpu=e200z4 -mattr=+vle" \\
      --prefix CHECK input.s > test.s
"""

from __future__ import annotations

import re
import shlex
import subprocess
import tempfile
from pathlib import Path

import click


def gnu_bytes(nxp_bin: Path, gnu_args: list[str], line: str) -> bytes:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "t.s"
        obj = Path(tmp) / "t.o"
        raw = Path(tmp) / "t.bin"
        src.write_text(f"\t.text\n\t{line}\n")
        subprocess.run([nxp_bin / "powerpc-eabivle-as", *gnu_args, str(src), "-o", str(obj)],
                       check=True, capture_output=True)
        subprocess.run([nxp_bin / "powerpc-eabivle-objcopy", "-O", "binary",
                        "--only-section=.text", str(obj), str(raw)], check=True)
        return raw.read_bytes()


def llvm_encoding(llvm_bin: Path, llvm_args: list[str], line: str) -> tuple[str, bytes]:
    mc = subprocess.run(
        [llvm_bin / "llvm-mc", "-triple=powerpc-unknown-eabi", *llvm_args, "-show-encoding"],
        input=f"\t{line}\n", capture_output=True, text=True, check=True)
    for out in mc.stdout.splitlines():
        m = re.match(r"\s*(.*?)\s*# encoding: \[(.*)\]", out)
        if m:
            data = bytes(int(b, 0) for b in m.group(2).split(","))
            return re.sub(r"\s+", " ", m.group(1)), data
    raise click.ClickException(f"no encoding for {line!r}: {mc.stdout}")


@click.command()
@click.option("--nxp-bin", type=click.Path(exists=True, path_type=Path), required=True)
@click.option("--llvm-bin", type=click.Path(exists=True, path_type=Path), required=True)
@click.option("--gnu-args", default="-mvle -me200z4")
@click.option("--llvm-args", default="-mcpu=e200z4 -mattr=+vle")
@click.option("--prefix", default="CHECK")
@click.argument("source", type=click.Path(exists=True, path_type=Path))
def main(nxp_bin: Path, llvm_bin: Path, gnu_args: str, llvm_args: str, prefix: str,
         source: Path) -> None:
    out = []
    for line in source.read_text().splitlines():
        text = line.strip()
        if not text or text.startswith("#"):
            out.append(line)
            continue
        want = gnu_bytes(nxp_bin, shlex.split(gnu_args), text)
        printed, got = llvm_encoding(llvm_bin, shlex.split(llvm_args), text)
        if got != want:
            raise click.ClickException(
                f"{text}: llvm-mc {got.hex(' ')} differs from NXP as {want.hex(' ')}")
        enc = ",".join(f"0x{b:02x}" for b in want)
        out.append(f"# {prefix}: {printed} # encoding: [{enc}]")
        out.append(text)
    click.echo("\n".join(out))


if __name__ == "__main__":
    main()
