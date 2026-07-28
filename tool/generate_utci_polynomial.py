#!/usr/bin/env python3
"""Generate lib/features/measurements/logic/thermal/utci_polynomial.dart from pythermalcomfort."""

from __future__ import annotations

import random
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DART = ROOT / "lib/features/measurements/logic/thermal/utci_polynomial.dart"
OUT_FIXTURE = ROOT / "test/fixtures/utci_reference.csv"
SOURCE_URL = (
    "https://raw.githubusercontent.com/CenterForTheBuiltEnvironment/"
    "pythermalcomfort/master/pythermalcomfort/models/utci.py"
)


def fetch_source() -> str:
    with urllib.request.urlopen(SOURCE_URL, timeout=30) as resp:
        return resp.read().decode("utf-8")


def extract_expression(source: str) -> str:
    start = source.index("def _utci_optimized")
    block = source[start:]
    ret = block.index("return (")
    depth = 0
    for i, ch in enumerate(block[ret:]):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return block[ret + len("return ") : ret + i + 1]
    raise RuntimeError("Could not extract polynomial expression")


def normalize_scientific(expr: str) -> str:
    """Convert (coeff * (10 ** (-n))) to coeffe-n form."""
    return re.sub(
        r"\(([+-]?[\d.]+)\s*\*\s*\(10\s\*\*\s*\(([-+]?\d+)\)\)\)",
        lambda m: f"{m.group(1)}e{m.group(2)}",
        expr,
    )


def python_to_dart(expr: str) -> str:
    expr = expr.strip()
    if expr.startswith("(") and expr.endswith(")"):
        expr = expr[1:-1]
    expr = normalize_scientific(expr)
    expr = expr.replace("delta_t_tr", "deltaTtr")
    # Split only on top-level " + " / " - " (not inside parens or exponents).
    tokens: list[str] = []
    depth = 0
    i = 0
    current = ""
    while i < len(expr):
        ch = expr[i]
        if ch == "(":
            depth += 1
            current += ch
        elif ch == ")":
            depth -= 1
            current += ch
        elif depth == 0 and expr[i : i + 3] in (" + ", " - "):
            if current.strip():
                tokens.append(current.strip())
            op = expr[i + 1]
            i += 2
            current = op
        else:
            current += ch
        i += 1
    if current.strip():
        tokens.append(current.strip())

    lines = ["    return ("]
    for idx, token in enumerate(tokens):
        token = token.strip()
        if idx == 0:
            lines.append(f"        {token}")
        elif token.startswith("+"):
            rest = token[1:].strip()
            if rest.startswith("-"):
                lines.append(f"        - {rest[1:].strip()}")
            else:
                lines.append(f"        + {rest}")
        elif token.startswith("-"):
            lines.append(f"        - {token[1:].strip()}")
        else:
            lines.append(f"        + {token}")
    lines.append("    );")
    return "\n".join(lines)


def build_dart(body: str) -> str:
    return f"""// GENERATED FILE — do not edit by hand.
// Regenerate with: python3 tool/generate_utci_polynomial.py

/// Bröde et al. (2012) 6th-order UTCI polynomial approximation.
///
/// Inputs:
/// - [tdb] air temperature °C
/// - [v] wind speed at 10 m m/s
/// - [deltaTtr] mean radiant temperature minus air temperature K
/// - [pa] water vapour pressure kPa
double utciPolynomial(
  double tdb,
  double v,
  double deltaTtr,
  double pa,
) {{
{body}
}}
"""


def evaluate_python(expr: str, tdb: float, v: float, delta_t_tr: float, pa: float) -> float:
    ns: dict = {}
    exec(f"def poly(tdb, v, delta_t_tr, pa):\n    return {expr}", ns)
    return float(ns["poly"](tdb, v, delta_t_tr, pa))


def write_fixture(expr: str) -> None:
    random.seed(42)
    rows = ["tdb,v,delta_t_tr,pa,utci"]
    for _ in range(2000):
        tdb = random.uniform(-50, 50)
        v = random.uniform(0.5, 17)
        delta = random.uniform(-30, 70)
        pa = random.uniform(0, 5)
        utci = evaluate_python(expr, tdb, v, delta, pa)
        rows.append(f"{tdb:.8f},{v:.8f},{delta:.8f},{pa:.8f},{utci:.12f}")
    OUT_FIXTURE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FIXTURE.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_FIXTURE} ({len(rows) - 1} rows)")


def main() -> int:
    print(f"Fetching {SOURCE_URL}")
    source = fetch_source()
    expr = extract_expression(source)
    print(f"Extracted expression with ~{expr.count('+ ') + expr.count('- ')} terms")

    body = python_to_dart(expr)
    OUT_DART.parent.mkdir(parents=True, exist_ok=True)
    OUT_DART.write_text(build_dart(body), encoding="utf-8")
    print(f"Wrote {OUT_DART}")

    write_fixture(expr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
