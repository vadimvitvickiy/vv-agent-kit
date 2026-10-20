#!/bin/bash
# The last commit adds an injectable query and a swallowed exception, alongside
# a cosmetic nit, so the review has to rank them.
source "$(dirname "${BASH_SOURCE[0]}")/../fixtures/scaffold-pricing.sh"
cat > orders.py <<'PY'
import sqlite3


def find_orders(conn, customer):
    """Returns every order the customer placed."""
    try:
        rows = conn.execute(f"SELECT id, total FROM orders WHERE customer = '{customer}'").fetchall()
    except Exception:
        return []
    data = [{"id": r[0], "total": r[1]} for r in rows]
    return data


def handle_orders_request(conn, query_params):
    return find_orders(conn, query_params["customer"])
PY
commit "add order lookup endpoint"
