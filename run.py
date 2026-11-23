"""Build the ShopLens database from scratch, run every analysis query, and run data-quality checks.

Usage:  python run.py            # build + run everything
        python run.py 03         # run only queries whose filename starts with 03
"""
import sqlite3, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "seed"))
from generate_data import build

ROOT = Path(__file__).parent
DB = ROOT / "shoplens.db"
MAX_ROWS = 12


def print_table(cur, rows):
    cols = [d[0] for d in cur.description]
    cells = [[("" if v is None else str(v)) for v in r] for r in rows]
    widths = [max(len(c), *(len(r[i]) for r in cells)) if cells else len(c) for i, c in enumerate(cols)]
    line = lambda vals: "  ".join(v.ljust(w) for v, w in zip(vals, widths))
    print(line(cols)); print(line(["-" * w for w in widths]))
    for r in cells[:MAX_ROWS]:
        print(line(r))
    if len(cells) > MAX_ROWS:
        print(f"... ({len(cells) - MAX_ROWS} more rows)")


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else ""
    DB.unlink(missing_ok=True)
    con = build(DB)
    counts = {t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
              for t in ("customers", "products", "orders", "order_items")}
    print("Built shoplens.db:", ", ".join(f"{v:,} {k}" for k, v in counts.items()))

    for path in sorted((ROOT / "queries").glob(f"{only}*.sql")):
        sql = path.read_text()
        question = next((l[2:].strip() for l in sql.splitlines() if "Business question" in l), "")
        print(f"\n=== {path.name} ===\n{question}\n")
        cur = con.execute(sql)
        print_table(cur, cur.fetchall())

    print("\n=== Data quality checks ===")
    failed = 0
    for name, n in con.execute((ROOT / "tests" / "data_quality.sql").read_text()):
        print(f"[{'PASS' if n == 0 else 'FAIL'}] {name}" + (f" ({n})" if n else ""))
        failed += n > 0
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
