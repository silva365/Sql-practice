-- ShopLens schema: a small online store.
PRAGMA foreign_keys = ON;

CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,
    parent_id     INTEGER REFERENCES categories(category_id)   -- NULL = top-level
);

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    category_id   INTEGER NOT NULL REFERENCES categories(category_id),
    unit_price    REAL NOT NULL CHECK (unit_price > 0)
);

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    email         TEXT NOT NULL UNIQUE,
    full_name     TEXT NOT NULL,
    city          TEXT,
    signup_date   TEXT NOT NULL                                 -- ISO date
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date    TEXT NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('completed','returned','cancelled'))
);

CREATE TABLE order_items (
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    REAL NOT NULL CHECK (unit_price > 0),         -- price at time of sale
    PRIMARY KEY (order_id, product_id)
);

-- Raw, untrusted import (loaded from seed/messy_customers.csv)
CREATE TABLE staging_customers (
    raw_email     TEXT,
    raw_name      TEXT,
    raw_city      TEXT,
    raw_signup    TEXT
);

CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_order_items_product  ON order_items(product_id);
