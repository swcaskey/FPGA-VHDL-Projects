#!/usr/bin/env python3

# Manual COE file generator for hello_world program

def dec2bin(num, digits):
    ret = bin(num)
    ret = ret[2:]
    ret = ret.zfill(digits)
    return ret

print("=== DATA SEGMENT ===")
data_str = "hello_world"
print(f"String: {data_str}")
print(f"Characters with ASCII values:")
data_coe = ['MEMORY_INITIALIZATION_RADIX=2;', 'MEMORY_INITIALIZATION_VECTOR=']

for i, char in enumerate(data_str):
    ascii_val = ord(char)
    binary = dec2bin(ascii_val, 16)
    print(f"  {char} = {ascii_val} = {binary}")
    if i < len(data_str) - 1:
        data_coe.append(binary + ",")
    else:
        data_coe.append(binary + ",")

# Add null terminator
data_coe.append(dec2bin(0, 16) + ";")
print(f"  (null) = 0 = {dec2bin(0, 16)}")

print("\nDATA COE OUTPUT:")
for line in data_coe:
    print(line)

print("\n=== TEXT SEGMENT ===")
# Instructions in order
instructions = [
    ("ori", "$r3", "$zero", 0),
    ("ori", "$r4", "$zero", 0),
    ("ori", "$r5", "$zero", 1),
    ("ori", "$r6", "$zero", 4096),
    ("lw", "$r7", "$r3", "val1"),  # label at address 0
    ("beq", "$r7", "$zero", "loop2"),  # loop2 is at instruction 9
    ("send", "$r7"),
    ("add", "$r3", "$r3", "$r5"),
    ("j", "beg"),  # beg is at instruction 4
    ("recv", "$r8"),
    ("add", "$r4", "$zero", "$zero"),
    ("beq", "$r4", "$r6", "loop2"),  # loop2 is at instruction 9
    ("wpix", "$r4", "$r8"),
    ("add", "$r4", "$r4", "$r5"),
    ("j", "loop3"),  # loop3 is at instruction 11
]

opcodes = {
    'add': '00000', 'sub': '00001', 'sll': '00010', 'srl': '00011', 'sra': '00100',
    'and': '00101', 'or': '00110', 'xor': '00111', 'slt': '01000', 'sgt': '01001',
    'seq': '01010', 'send': '01011', 'recv': '01100', 'jr': '01101', 'wpix': '01110',
    'rpix': '01111', 'beq': '10000', 'bne': '10001', 'ori': '10010', 'lw': '10011',
    'sw': '10100', 'j': '11000', 'jal': '11001', 'clrscr': '11010', 'la': '10010'
}

registers = {
    '$zero': '00000', '$pc': '00001', '$ra': '00010'
}
for i in range(3, 32):
    registers[f'$r{i}'] = dec2bin(i, 5)

text_coe = ['MEMORY_INITIALIZATION_RADIX=2;', 'MEMORY_INITIALIZATION_VECTOR=']

print(f"Total instructions: {len(instructions)}")
for idx, instr in enumerate(instructions):
    opcode_name = instr[0]
    opcode = opcodes[opcode_name]
    binary_instr = opcode
    
    print(f"\n[{idx}] {instr}")
    print(f"  Opcode: {opcode_name} = {opcode}")
    
    # Determine instruction type
    instr_type = opcode[0:2]
    if instr_type == '00' or instr_type == '01':  # R-type
        # Format: opcode (5) + reg1 (5) + reg2 (5) + reg3 (5) + padding (12)
        for arg_idx in range(1, len(instr)):
            binary_instr += registers[instr[arg_idx]]
        binary_instr = binary_instr.ljust(32, '0')
        print(f"  Type: R-type (registers)")
    elif instr_type == '10':  # I-type
        if opcode_name in ['lw', 'sw']:
            # Format: opcode (5) + reg1 (5) + reg2 (5) + immediate (16)
            binary_instr += registers[instr[1]] + registers[instr[2]]
            binary_instr += dec2bin(0, 16)  # immediate for data label (would be resolved)
        elif opcode_name in ['beq', 'bne']:
            # Format: opcode (5) + reg1 (5) + reg2 (5) + immediate (16)
            binary_instr += registers[instr[1]] + registers[instr[2]]
            # Jump target (label index)
            binary_instr += dec2bin(0, 16)  # Would be resolved to label address
        else:  # ori, addi, etc
            # Format: opcode (5) + reg1 (5) + reg2 (5) + immediate (16)
            binary_instr += registers[instr[1]] + registers[instr[2]]
            binary_instr += dec2bin(int(instr[3]), 16) if isinstance(instr[3], (int, str)) and str(instr[3]).isdigit() else dec2bin(0, 16)
        print(f"  Type: I-type (immediate)")
    elif instr_type == '11':  # J-type
        # Format: opcode (5) + padding (11) + address (16)
        binary_instr += dec2bin(0, 27)  # Would be resolved to label address
        print(f"  Type: J-type (jump)")
    else:  # For send, recv, wpix, rpix
        if opcode_name in ['send', 'recv']:
            # R-type format with single register
            binary_instr += registers[instr[1]]
            binary_instr = binary_instr.ljust(32, '0')
        elif opcode_name == 'wpix':
            # wpix $r4 $r8 - special format
            binary_instr += registers[instr[1]] + registers[instr[2]]
            binary_instr = binary_instr.ljust(32, '0')
        print(f"  Type: Special")
    
    print(f"  Binary: {binary_instr} ({len(binary_instr)} bits)")
    
    if idx < len(instructions) - 1:
        text_coe.append(binary_instr + ",")
    else:
        text_coe.append(binary_instr + ";")

print("\n\nTEXT COE OUTPUT:")
for line in text_coe:
    print(line)

# Write files
print("\n\n=== Writing COE files ===")
with open('hello_world_data.coe', 'w') as f:
    for line in data_coe:
        f.write(line + '\n')
print("Wrote hello_world_data.coe")

with open('hello_world_text.coe', 'w') as f:
    for line in text_coe:
        f.write(line + '\n')
print("Wrote hello_world_text.coe")
