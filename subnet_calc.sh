#!/bin/bash

# --- Usage Check ---
if [ "$#" -ne 3 ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <Parent_IP> <Parent_CIDR> <Hosts_Needed>"
    echo "Example: $0 10.1.0.0 16 2000"
    exit 1
fi

# --- Inputs ---
PARENT_IP=$1
PARENT_CIDR=$2
HOSTS=$3

# --- Python Logic for Math & Formatting ---
python3 -c "
import ipaddress
import math
import sys

# 1. Parse Inputs safely
try:
    parent_ip = '$PARENT_IP'
    parent_cidr = int('$PARENT_CIDR')
    hosts_req = int('$HOSTS')
except ValueError:
    print('Error: CIDR and Hosts must be integers.')
    sys.exit(1)

# 2. Calculate Optimal Size
# Formula: 2^h >= hosts + 2 (Network + Broadcast)
needed_total = hosts_req + 2
host_bits = math.ceil(math.log2(needed_total))
new_cidr = 32 - host_bits

# 3. Validation
if new_cidr < parent_cidr:
    print(f'Error: Needed /{new_cidr} but parent is /{parent_cidr}. Parent is too small!')
    sys.exit(1)

# 4. Create Subnet Object
# We use strict=False to allow passing '10.1.0.0' even if the mask changes
try:
    subnet = ipaddress.IPv4Network(f'{parent_ip}/{new_cidr}', strict=False)
except ValueError as e:
    print(f'Error generating subnet: {e}')
    sys.exit(1)

# --- OUTPUT BLOCK 1: Summary ---
print('Subnet Calculation Results')
print('---------------------------------------------')
print(f' Parent Subnet:     {parent_ip}/{parent_cidr}')
print(f' Hosts Needed:      {hosts_req} (including 2 overhead)')
print(f' Total Capacity:    {subnet.num_addresses} IPs')
print(f' CIDR Used:         /{new_cidr}')
print('---------------------------------------------')
print('') 

# --- OUTPUT BLOCK 2: Detailed Table ---
rows = [
    ['Property', 'IP Address', 'Notes'],
    ['-'*15, '-'*15, '-'*30],
    ['Network Address', str(subnet.network_address), 'Identifies the subnet'],
    ['First Usable IP', str(subnet.network_address + 1), 'Gateway / First Host'],
    ['Last Usable IP', str(subnet.broadcast_address - 1), 'Last Host'],
    ['Broadcast Addr', str(subnet.broadcast_address), 'Broadcast Traffic'],
    ['Subnet Mask', str(subnet.netmask), f'Decimal for /{new_cidr}']
]

for row in rows:
    print(f'{row[0]:<18} {row[1]:<18} {row[2]}')
print('')
"