#!/bin/bash
# The crash surfaces in annual_savings_percent; the cause is parse_price turning
# a missing price ("") into 0 instead of rejecting it.
source "$(dirname "${BASH_SOURCE[0]}")/../fixtures/scaffold-pricing.sh"
