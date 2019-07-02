# Basic single-cycle MIPS processor

## Try it
Get [Icarus Verilog](https://github.com/steveicarus/iverilog), then:

```
$ python3 asm/asm.py
$ ./rtl/test.sh
```

## Supported instructions

### R-type

- `add`
- `sub`
- `and`
- `or`
- `slt`

### I-type

- `lw`
- `sw`
- `beq`

## References
- D. Harris & S. Harris, Digital Design and Computer Architecture, 2nd Ed., Waltham, MA: Morgan Kaufmann, 2013
- [MIPS32® Architecture For Programmers Volume II: The MIPS32® Instruction Set](https://ti.tuwien.ac.at/cps/teaching/courses/cavo/files/MIPS32-IS.pdf)