def parse_price(text):
    """Parses a price such as "$9.99" into a float."""
    return float(text.strip().lstrip("$") or 0)


def annual_savings_percent(monthly, annual):
    """How much cheaper a year is than twelve months, as a whole percent."""
    full = monthly * 12
    return int((full - annual) / full * 100)


def savings_text(monthly_text, annual_text):
    """The badge shown on the pricing page, e.g. "Save 16%"."""
    monthly = parse_price(monthly_text)
    annual = parse_price(annual_text)
    return f"Save {annual_savings_percent(monthly, annual)}%"
