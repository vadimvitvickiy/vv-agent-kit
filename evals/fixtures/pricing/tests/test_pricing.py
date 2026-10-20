import unittest

from pricing import annual_savings_percent, parse_price, savings_text


class SavingsTest(unittest.TestCase):
    def test_savings_truncates(self):
        self.assertEqual(annual_savings_percent(10, 100), 16)

    def test_savings_quarter(self):
        self.assertEqual(annual_savings_percent(10, 90), 25)

    def test_savings_third(self):
        self.assertEqual(annual_savings_percent(10, 80), 33)

    def test_badge(self):
        self.assertEqual(savings_text("$10", "$90"), "Save 25%")

    def test_parse_price(self):
        self.assertEqual(parse_price("$9.99"), 9.99)


if __name__ == "__main__":
    unittest.main()
