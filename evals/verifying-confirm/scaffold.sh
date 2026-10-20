#!/bin/bash
# The uncommitted "fix" rounds up, which is right for 16.67 but breaks 33.33.
source "$(dirname "${BASH_SOURCE[0]}")/../fixtures/scaffold-pricing.sh"
sed -i.bak 's/^def annual_savings_percent/import math\n\n\ndef annual_savings_percent/; s/return int((full - annual) \/ full \* 100)/return math.ceil((full - annual) \/ full * 100)/' pricing.py && rm pricing.py.bak
