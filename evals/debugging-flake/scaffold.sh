#!/bin/bash
# A module-level cache leaks between tests: test_default_price fails whenever
# another test has cached the plan first, and passes alone.
source "$(dirname "${BASH_SOURCE[0]}")/../fixtures/scaffold-pricing.sh"
cat > cache.py <<'PY'
_prices = {}


def cached_price(plan, load):
    """Returns the plan's price, loading it once."""
    if plan not in _prices:
        _prices[plan] = load()
    return _prices[plan]
PY
cat > tests/test_cache.py <<'PY'
import unittest

from cache import cached_price


class CachingTest(unittest.TestCase):
    def test_loads_once(self):
        calls = []
        cached_price("pro", lambda: calls.append(1) or 10)
        cached_price("pro", lambda: calls.append(1) or 10)
        self.assertEqual(len(calls), 1)


class LookupTest(unittest.TestCase):
    def test_default_price(self):
        self.assertEqual(cached_price("pro", lambda: 20), 20)
PY
commit "cache plan prices"
