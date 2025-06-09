-- Tabel produk
CREATE TABLE produk (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    gambar VARCHAR(255),
    harga INTEGER NOT NULL,
    stok INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel order
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,            -- UID Firestore customer
    total_harga INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Diproses',
    metode_pembayaran VARCHAR(50) NOT NULL,
    bukti_pembayaran VARCHAR(255),
    latitude DOUBLE PRECISION,                 -- Lokasi customer saat order
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel order_detail (untuk detail produk yang dipesan)
CREATE TABLE order_detail (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    produk_id INTEGER NOT NULL REFERENCES produk(id),
    jumlah INTEGER NOT NULL,
    harga_satuan INTEGER NOT NULL
);

CREATE TABLE ulasan (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,       -- UID dari Firebase Auth customer
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_order_review UNIQUE (order_id, user_id)
);

-- Tabel promo (kalau nanti mau pindah promo ke PostgreSQL)
-- CREATE TABLE promo (
--     id SERIAL PRIMARY KEY,
--     kode VARCHAR(50) UNIQUE NOT NULL,
--     deskripsi TEXT,
--     diskon_persen INTEGER CHECK(diskon_persen >= 0 AND diskon_persen <= 100),
--     tanggal_mulai DATE NOT NULL,
--     tanggal_selesai DATE NOT NULL,
--     aktif BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

select * from produk

select * from orders
select id and qrcode * from orders

SELECT *
FROM orders
WHERE status IS selesai;

SELECT *
FROM orders
WHERE status = 'Selesai';

delete from orders
where id = 19

DELETE FROM orders
WHERE id IN (1, 3, 4, 5, 6, 7, 8, 13, 15);


CREATE TABLE ulasan (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,       -- UID dari Firebase Auth customer
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_order_review UNIQUE (order_id, user_id)
);
