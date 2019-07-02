import types
from struct import pack

# instruction set reference:
# https://ti.tuwien.ac.at/cps/teaching/courses/cavo/files/MIPS32-IS.pdf

# opcodes
OP_RTYPE    = 0b000000
OP_BEQ      = 0b000100
OP_LW       = 0b100011
OP_SW       = 0b101011
OP_ADDI     = 0b001000

# funct field codes
FUNCT_ADD   = 0b100000
FUNCT_AND   = 0b100100
FUNCT_OR    = 0b100101
FUNCT_SUB   = 0b100010
FUNCT_SLT   = 0b101010

# registers
t0 = 8
t1 = 9
t2 = 10
t3 = 11
t4 = 12
t5 = 13
t6 = 14
t7 = 15

# instruction types
def R_TYPE(op, rs, rt, rd, shamt, funct):
    return ((op << 26) |
            (rs << 21) |
            (rt << 16) |
            (rd << 11) |
            (shamt << 6) |
            (funct))

def I_TYPE(op, rs, rt, imm):
    return ((op << 26) |
            (rs << 21) |
            (rt << 16) |
            (imm))

# instructions

# ADD rd, rs, rt
def ADD(rd, rs, rt):
    return R_TYPE(OP_RTYPE, rs, rt, rd, 0, FUNCT_ADD)

# SUB rd, rs, rt
def SUB(rd, rs, rt):
    return R_TYPE(OP_RTYPE, rs, rt, rd, 0, FUNCT_SUB)

# AND rd, rs, rt
def AND(rd, rs, rt):
    return R_TYPE(OP_RTYPE, rs, rt, rd, 0, FUNCT_AND)

# OR rd, rs, rt
def OR(rd, rs, rt):
    return R_TYPE(OP_RTYPE, rs, rt, rd, 0, FUNCT_OR)

# SLT rd, rs, rt
def SLT(rd, rs, rt):
    return R_TYPE(OP_RTYPE, rs, rt, rd, 0, FUNCT_SLT)

# ADDI rt, rs, immediate
def ADDI(rt, rs, imm):
    return I_TYPE(OP_ADDI, rs, rt, imm)

# LW rt, offset(base)
def LW(rt, base, offset):
    return I_TYPE(OP_LW, base, rt, offset)

# SW rt, offset(base)
def SW(rt, base, offset):
    return I_TYPE(OP_SW, base, rt, offset)

# BEQ rs, rt, offset
def BEQ(rs, rt, offset):
    if isinstance(offset, str):
        return lambda resolve: I_TYPE(OP_BEQ, rs, rt, resolve(offset))
    return I_TYPE(OP_BEQ, rs, rt, offset)

def LABEL(label):
    return label

# write to file

code = [
    ADDI(t0, 0, 1),
    ADD(t1, t0, 0),
    ADDI(t2, 0, 5),
    BEQ(t0, t1, 'here'), #3
    ADDI(t2, 0, 0),
    LABEL('here'),
    ADDI(t3, 0, 3), #5
    ADDI(t0, 0, 0),
]

flat_code = []
labels = {}

# build symbol table
for x in code:
    if isinstance(x, str):
        assert x not in labels
        labels[x] = len(flat_code) #5
    else:
        flat_code += [x]

# resolve labels
for i, x in enumerate(flat_code):
    if isinstance(x, types.LambdaType):
        flat_code[i] = x(lambda label: labels[label] - i - 1)

binary = False

if binary:
    code_bytes = pack('2I', *flat_code)
    with open('code.bin', 'wb') as f:
        f.write(code_bytes)
else:
    with open('rtl/code.dat', 'w') as f:
        for i in flat_code:
            text = format(i, '032b')
            print(text)
            f.write(text + '\n')