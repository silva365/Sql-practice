"""Generate reproducible fake store data into an SQLite database."""
import csv, random, sqlite3
from datetime import date, timedelta
from pathlib import Path

random.seed(42)
HERE = Path(__file__).parent

FIRST = "Ana Ben Chloe Diego Emma Farah Gus Hana Ivan Jade Kofi Lena Mateo Nia Omar Priya Quinn Rosa Sam Tara Uma Victor Wen Yara Zoe".split()
LAST = "Silva Smith Nguyen Patel Garcia Kim Okafor Muller Rossi Cohen Tanaka Lopez Brown Ali Novak".split()
CITIES = ["Austin", "Boston", "Chicago", "Denver", "Miami", "Seattle", "Portland", "Atlanta"]

CATEGORY_TREE = {  # top-level -> subcategories -> products (name, price)
    "Electronics": {"Audio": [("Wireless Earbuds", 79), ("Bluetooth Speaker", 49), ("Studio Headphones", 149)],
                    "Computers": [("Laptop Stand", 35), ("Mechanical Keyboard", 99), ("USB-C Hub", 39)]},
    "Home": {"Kitchen": [("Pour-Over Kettle", 45), ("Chef Knife", 65), ("Cast Iron Pan", 40)],
             "Decor": [("Linen Throw", 55), ("Ceramic Vase", 30), ("Desk Lamp", 42)]},
    "Outdoors": {"Camping": [("2-Person Tent", 180), ("Sleeping Bag", 90), ("Camp Stove", 60)],
                 "Fitness": [("Yoga Mat", 28), ("Resistance Bands", 18), ("Water Bottle", 22)]},
}

def build(db_path: Path):
    con = sqlite3.connect(db_path)
    con.executescript((HERE.parent / "schema" / "01_tables.sql").read_text())

    # Categories + products
    cat_id = prod_id = 0
    products = []
    for top, subs in CATEGORY_TREE.items():
        cat_id += 1; top_id = cat_id
        con.execute("INSERT INTO categories VALUES (?,?,NULL)", (top_id, top))
        for sub, items in subs.items():
            cat_id += 1
            con.execute("INSERT INTO categories VALUES (?,?,?)", (cat_id, sub, top_id))
            for name, price in items:
                prod_id += 1
                products.append((prod_id, name, cat_id, float(price)))
    con.executemany("INSERT INTO products VALUES (?,?,?,?)", products)

    # Customers: signups spread over 2024-2025
    start = date(2024, 1, 1)
    customers = []
    for cid in range(1, 2001):
        f, l = random.choice(FIRST), random.choice(LAST)
        signup = start + timedelta(days=random.randint(0, 700))
        customers.append((cid, f"{f.lower()}.{l.lower()}{cid}@example.com", f"{f} {l}",
                          random.choice(CITIES), signup.isoformat()))
    con.executemany("INSERT INTO customers VALUES (?,?,?,?,?)", customers)

    # Orders: each customer has a "loyalty" level that drives repeat purchases
    end = date(2025, 12, 31)
    oid = 0
    orders, items = [], []
    for cid, *_, signup in customers:
        d = date.fromisoformat(signup)
        loyalty = random.random()
        while d <= end:
            oid += 1
            status = random.choices(["completed", "returned", "cancelled"], [90, 6, 4])[0]
            orders.append((oid, cid, d.isoformat(), status))
            for p in random.sample(products, random.choices([1, 2, 3], [60, 30, 10])[0]):
                # Holiday season bump on quantity
                qty = random.choices([1, 2, 3], [75, 20, 5])[0] + (1 if d.month == 12 and random.random() < .2 else 0)
                items.append((oid, p[0], qty, p[3]))
            if random.random() > 0.35 + loyalty * 0.6:  # churn chance
                break
            d += timedelta(days=random.randint(10, 120))
    con.executemany("INSERT INTO orders VALUES (?,?,?,?)", orders)
    con.executemany("INSERT INTO order_items VALUES (?,?,?,?)", items)

    # Messy staging data
    with open(HERE / "messy_customers.csv", newline="") as fh:
        rows = [tuple(r.values()) for r in csv.DictReader(fh)]
    con.executemany("INSERT INTO staging_customers VALUES (?,?,?,?)", rows)

    con.commit()
    return con
