#!/bin/bash
# A second caller of the renamed function, and a test that already fails for an
# unrelated reason before the change — the report has to mention it.
source "$(dirname "${BASH_SOURCE[0]}")/../fixtures/scaffold-pricing.sh"
cat > report.py <<'PY'
from pricing import annual_savings_percent


def weekly_report(plans):
    return [f"{name}: {annual_savings_percent(m, a)}%" for name, m, a in plans]
PY
cat > tests/test_tax.py <<'PY'
import unittest


def with_tax(amount, rate=0.2):
    return round(amount * rate, 2)


class TaxTest(unittest.TestCase):
    def test_with_tax_adds_the_tax(self):
        self.assertEqual(with_tax(10), 12.0)
PY
commit "add weekly report and tax helper"
