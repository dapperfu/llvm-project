#!/usr/bin/env bash
# Run the e200/VLE GNU behaviour probes against the NXP powerpc-eabivle
# toolchain and write raw evidence into ./out.  The toolchain binaries are
# i386 static executables; run this outside restrictive sandboxes.
#
# Usage: NXP_EABIVLE_TOOLCHAIN=/path/to/powerpc-eabivle-4_9 ./run-probes.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
TC="${NXP_EABIVLE_TOOLCHAIN:-$HERE/../../../S32DS/build_tools/powerpc-eabivle-4_9}"
BIN="$TC/bin"
AS="$BIN/powerpc-eabivle-as"
GCC="$BIN/powerpc-eabivle-gcc"
OBJDUMP="$BIN/powerpc-eabivle-objdump"
READELF="$BIN/powerpc-eabivle-readelf"
LD="$BIN/powerpc-eabivle-ld"
OUT="$HERE/out"
mkdir -p "$OUT"
cd "$OUT" || exit 1

if [ ! -x "$AS" ]; then
  echo "toolchain not found: $TC" >&2
  exit 1
fi

{
  "$GCC" --version | head -1
  "$AS" --version | head -1
} > versions.txt

# P01: mode directives.
: > p01-directives.txt
for d in '.vle' '.novle' '.machine e200z4' '.machine push' '.machine vle'; do
  printf '\t.text\n\t%s\n\tse_nop\n' "$d" > t.s
  r=$("$AS" -mvle t.s -o t.o 2>&1 | sed -n 2p)
  echo "${d} => ${r:-accepted}" >> p01-directives.txt
done

# P02: section flags, apuinfo and e_flags.
cp "$HERE/p02-sections.s" p02-sections.s
: > p02-sections.txt
for opt in "" "-mvle" "-mbooke"; do
  echo "== as $opt p02-sections.s" >> p02-sections.txt
  "$AS" $opt p02-sections.s -o p02.o >> p02-sections.txt 2>&1
done
cat > p02b.s <<'EOF'
	.text
plain_text:
	add 3,4,5
	se_blr
	.section .text_vle_flag,"axv"
vle_flag:
	se_add 3,4
	se_blr
	.section .text_other,"ax"
other:
	se_blr
	.data
d:	.long 1
	.section .rodata_v,"av"
	.long 2
EOF
for opt in "-mvle" "-me200z4" "-mvle -memb"; do
  echo "== as $opt p02b.s" >> p02-sections.txt
  "$AS" $opt p02b.s -o p02b.o >> p02-sections.txt 2>&1
  "$READELF" -h -S -W -n p02b.o | grep -E 'Flags|\] \.|APUinfo|description' >> p02-sections.txt
  "$OBJDUMP" -s -j .PPC.EMB.apuinfo p02b.o | tail -2 >> p02-sections.txt
done
"$OBJDUMP" -d p02b.o > p02b-objdump.txt

# P03: VLE-mode mnemonic acceptance, one instruction per assembly.
: > p03-vle-acceptance.txt
while IFS= read -r l; do
  [ -z "$l" ] && continue
  printf '\t.text\nx:\n\t%s\n' "$l" > l.s
  r=$("$AS" -mvle -me200z4 l.s -o l.o 2>&1 | sed -n 2p | sed 's/.*Error: //')
  if [ -z "$r" ]; then
    b=$("$OBJDUMP" -d -M e200z4,vle l.o | grep -E '^ +0:' | sed 's/^ *0:\t//')
    echo "OK  | $l | $b" >> p03-vle-acceptance.txt
  else
    echo "ERR | $l | $r" >> p03-vle-acceptance.txt
  fi
done < "$HERE/p03-mnemonics.txt"

# P03b: Book E-mode acceptance of the same list.  binutils 2.28 resets to a
# minimal Book E table for "-me200z4 -mno-vle" (even isel is rejected), so
# -me500x2 is used as the most complete Book E reference available.
: > p03-booke-acceptance.txt
while IFS= read -r l; do
  [ -z "$l" ] && continue
  printf '\t.text\nx:\n\t%s\n' "$l" > l.s
  r=$("$AS" -me500x2 l.s -o l.o 2>&1 | sed -n 2p | sed 's/.*Error: //')
  if [ -z "$r" ]; then
    b=$("$OBJDUMP" -d -M booke,spe l.o | grep -E '^ +0:' | sed 's/^ *0:\t//')
    echo "OK  | $l | $b" >> p03-booke-acceptance.txt
  else
    echo "ERR | $l | $r" >> p03-booke-acceptance.txt
  fi
done < "$HERE/p03-mnemonics.txt"

# P04: VLE relocations and specifiers.
cp "$HERE/p04-relocs.s" p04-relocs.s
"$AS" -mvle p04-relocs.s -o p04.o > p04-relocs.txt 2>&1
"$READELF" -r -W p04.o >> p04-relocs.txt
"$OBJDUMP" -dr p04.o >> p04-relocs.txt

# P05: alignment fill in VLE sections.
printf '\t.text\n\tse_blr\n\t.p2align 4\n\tse_blr\n\t.p2align 3\n\te_nop\n\t.balign 8\n\tse_blr\n' > p05.s
"$AS" -mvle p05.s -o p05.o > p05-align.txt 2>&1
"$OBJDUMP" -d p05.o >> p05-align.txt
"$READELF" -S -W p05.o | grep '\.text' >> p05-align.txt

# P06/P07: branch range and parity (relaxation policy).
{ printf '\t.text\nf:\n\tse_b far\n\tse_bc 0,2,far\n\te_bc 0,2,far2\n'
  printf '\t.space 300\nfar:\n\tse_blr\n\t.space 40000\nfar2:\n\tse_blr\n'; } > p06.s
"$AS" -mvle p06.s -o p06.o > p06-relax.txt 2>&1
printf '\t.text\nf:\n\te_b f+1\n' > p07.s
"$AS" -mvle p07.s -o p07.o >> p06-relax.txt 2>&1

# P08: Book E EABI small-data relocations.
printf '\t.text\n\tlwz 3, sdav@sda21(0)\n\taddi 3, 0, sdav@sda21\n\tlwz 3, sdav@sdarel(13)\n\t.section .sdata,"aw"\nsdav: .long 0\n\t.section .sdata2,"a"\nsd2: .long 0\n\t.text\n\tlwz 4, sd2@sda21(0)\n' > p08.s
"$AS" -mbooke p08.s -o p08.o > p08-emb-relocs.txt 2>&1
"$READELF" -r -W p08.o >> p08-emb-relocs.txt

# P09: SPR operand forms.
: > p09-spr.txt
for l in 'mfspr 3,1008' 'mfspr 3,hid0' 'mfhid0 3' 'mtspr 1010,3' 'mfspr 3,568' 'mtspr 63,3' 'mfspefscr 3'; do
  printf '\t.text\n\t%s\n' "$l" > l.s
  r=$("$AS" -mvle -me200z4 l.s -o l.o 2>&1 | sed -n 2p | sed 's/.*Error: //')
  if [ -z "$r" ]; then
    echo "OK  | $l | $("$OBJDUMP" -d -M e200z4,vle l.o | grep -E '^ +0:' | sed 's/^ *0:\t//')" >> p09-spr.txt
  else
    echo "ERR | $l | $r" >> p09-spr.txt
  fi
done

# P10: predefined macros per -mcpu and option.
"$GCC" -E -dM -x c /dev/null | sort > macros-default.txt
: > p10-macros.txt
for cpu in e200z0 e200z1 e200z2 e200z3 e200z4 e200z6 e200z7 e200z759; do
  for o in "" "-mno-vle" "-mvle" "-mhard-float" "-mspe"; do
    r=$("$GCC" -mcpu=$cpu $o -E -dM -x c /dev/null 2>&1 | sort)
    if echo "$r" | grep -q 'error'; then
      echo "$cpu $o => $(echo "$r" | grep -m1 error)" >> p10-macros.txt
    else
      add=$(comm -13 macros-default.txt <(echo "$r") | grep -v -E 'altivec|vsx|vector|pixel|bool' | sed 's/#define //' | tr '\n' ';')
      del=$(comm -23 macros-default.txt <(echo "$r") | sed 's/#define //' | tr '\n' ';')
      echo "$cpu $o => +[$add] -[$del]" >> p10-macros.txt
    fi
  done
done

# P11: ABI and code generation samples.
cp "$HERE/p10-abi.c" p10-abi.c
for cfg in "z4-vle:-mcpu=e200z4 -mvle" "z4-booke:-mcpu=e200z4 -mno-vle" \
           "z4-hardfloat:-mcpu=e200z4 -mvle -mhard-float" \
           "z4-spe:-mcpu=e200z4 -mno-vle -mspe -mhard-float" \
           "z0:-mcpu=e200z0" "z7-vle-os:-mcpu=e200z7 -mvle -Os"; do
  name=${cfg%%:*}; flags=${cfg#*:}
  "$GCC" $flags -O2 -std=gnu99 -S p10-abi.c -o "p11-$name.s" > "p11-$name.log" 2>&1
  "$GCC" $flags -O2 -std=gnu99 -c p10-abi.c -o "p11-$name.o" >> "p11-$name.log" 2>&1
  "$READELF" -S -W -h "p11-$name.o" | grep -E 'Flags|\] \.' > "p11-$name.sections.txt"
done
"$GCC" -mcpu=e200z4 -mno-vle -mspe -O2 -std=gnu99 -g -c p10-abi.c -o p11-cfi.o > /dev/null 2>&1
"$READELF" --debug-dump=frames p11-cfi.o > p11-spe-cfi.txt 2>&1

# P12: empirical 16/32-bit length map over every first halfword.
# Each sample is [h][se_nop][se_nop][se_nop]; an instruction starting at
# offset +2 means h was decoded as a 16-bit instruction.
python3 - <<'EOF'
import struct
with open('p12-halfwords.bin', 'wb') as f:
    for h in range(0x10000):
        f.write(struct.pack('>HHHH', h, 0x4400, 0x4400, 0x4400))
EOF
"$BIN/powerpc-eabivle-objcopy" -I binary -O elf32-powerpc -B powerpc:vle \
  --rename-section .data=.text,alloc,load,readonly,code,contents \
  p12-halfwords.bin p12-halfwords.o
"$OBJDUMP" -D -M e200z4,vle,spe,efs,efs2 -b elf32-powerpc p12-halfwords.o \
  > p12-halfwords.dis 2>&1
python3 - <<'EOF'
import re
starts = {}
for line in open('p12-halfwords.dis'):
    m = re.match(r'\s+([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)', line)
    if m:
        starts[int(m.group(1), 16)] = (m.group(2).strip(), m.group(3).strip())
counts = {16: 0, 32: 0, 'invalid': 0}
with open('p12-length-map.txt', 'w') as out:
    for h in range(0x10000):
        base = h * 8
        raw, text = starts.get(base, ('', ''))
        if (base + 2) in starts and len(raw.split()) == 2:
            kind = 16
        else:
            kind = 32
        if not text or text.startswith('.') or 'illegal' in text and h != 0:
            k = 'invalid'
        else:
            k = kind
        counts[k] += 1
        out.write('%04x %s %s\n' % (h, k, text))
    out.write('# totals %r\n' % counts)
EOF
tail -1 p12-length-map.txt

echo "probes complete: $OUT"
