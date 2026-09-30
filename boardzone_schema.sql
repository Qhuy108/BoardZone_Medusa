-- =============================================================================
-- CƠ SỞ DỮ LIỆU THƯƠNG MẠI ĐIỆN TỬ BOARD GAME - BOARDZONE (EC312)
-- Hệ quản trị CSDL: PostgreSQL
-- Chuẩn hóa: 3NF (Third Normal Form)
-- =============================================================================

-- Bật extension UUID nếu cần
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. PHÂN HỆ NGƯỜI DÙNG & PHÂN QUYỀN
-- =============================================================================

-- Bảng Quản trị viên / Nhân viên (Users)
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'STAFF' CHECK (role IN ('ADMIN', 'STAFF', 'WAREHOUSE')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Bảng Khách hàng (Customers)
CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGSERIAL PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    avatar_url VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Bảng Sổ địa chỉ khách hàng (Customer Addresses)
CREATE TABLE IF NOT EXISTS customer_addresses (
    address_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    receiver_name VARCHAR(100) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    ward VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. PHÂN HỆ DANH MỤC & SẢN PHẨM BOARD GAME (N - N)
-- =============================================================================

-- Bảng Danh mục / Thể loại (Categories)
CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    slug VARCHAR(150) UNIQUE NOT NULL,
    description TEXT,
    parent_id INT REFERENCES categories(category_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Bảng Sản phẩm Board Game (Products)
CREATE TABLE IF NOT EXISTS products (
    product_id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    slug VARCHAR(250) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    original_price NUMERIC(12, 2) CHECK (original_price IS NULL OR original_price >= price),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    min_players INT NOT NULL CHECK (min_players > 0),
    max_players INT NOT NULL CHECK (max_players >= min_players),
    min_playtime INT CHECK (min_playtime IS NULL OR min_playtime > 0),
    max_playtime INT CHECK (max_playtime IS NULL OR max_playtime >= min_playtime),
    min_age INT CHECK (min_age IS NULL OR min_age >= 0),
    publisher VARCHAR(150),
    designer VARCHAR(150),
    language VARCHAR(50) DEFAULT 'Tiếng Việt',
    thumbnail_url VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Bảng liên kết Nhiều - Nhiều Sản phẩm & Danh mục (Product Categories)
CREATE TABLE IF NOT EXISTS product_categories (
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);

-- Bảng Bộ sưu tập ảnh sản phẩm (Product Images)
CREATE TABLE IF NOT EXISTS product_images (
    image_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. PHÂN HỆ GIỎ HÀNG (Cart)
-- =============================================================================

CREATE TABLE IF NOT EXISTS carts (
    cart_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id BIGINT REFERENCES customers(customer_id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id BIGSERIAL PRIMARY KEY,
    cart_id UUID NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cart_id, product_id)
);

-- =============================================================================
-- 4. PHÂN HỆ MÃ GIẢM GIÁ & KHUYẾN MÃI (Coupons)
-- =============================================================================

CREATE TABLE IF NOT EXISTS coupons (
    coupon_id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
    discount_value NUMERIC(12, 2) NOT NULL CHECK (discount_value > 0),
    min_order_value NUMERIC(12, 2) NOT NULL DEFAULT 0,
    max_discount_amount NUMERIC(12, 2),
    usage_limit INT,
    used_count INT NOT NULL DEFAULT 0,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL CHECK (end_date > start_date),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. PHÂN HỆ ĐƠN HÀNG, CHI TIẾT & LỊCH SỬ (Orders)
-- =============================================================================

CREATE TABLE IF NOT EXISTS orders (
    order_id BIGSERIAL PRIMARY KEY,
    order_code VARCHAR(30) UNIQUE NOT NULL,
    customer_id BIGINT REFERENCES customers(customer_id) ON DELETE RESTRICT,
    coupon_id INT REFERENCES coupons(coupon_id) ON DELETE SET NULL,
    order_status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (order_status IN ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPING', 'COMPLETED', 'CANCELLED')),
    subtotal_amount NUMERIC(12, 2) NOT NULL CHECK (subtotal_amount >= 0),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    shipping_fee NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    shipping_full_name VARCHAR(100) NOT NULL,
    shipping_phone VARCHAR(20) NOT NULL,
    shipping_address TEXT NOT NULL,
    customer_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    product_name_snap VARCHAR(200) NOT NULL,
    sku_snap VARCHAR(50) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    total_price NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0)
);

CREATE TABLE IF NOT EXISTS order_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    status_from VARCHAR(50),
    status_to VARCHAR(50) NOT NULL,
    changed_by_user_id INT REFERENCES users(user_id) ON DELETE SET NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. PHÂN HỆ THANH TOÁN (Payments)
-- =============================================================================

CREATE TABLE IF NOT EXISTS payments (
    payment_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('COD', 'VNPAY', 'MOMO', 'BANK_TRANSFER')),
    transaction_id VARCHAR(100),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    payment_status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),
    payment_gateway_response JSONB,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. PHÂN HỆ ĐÁNH GIÁ SẢN PHẨM (Reviews)
-- =============================================================================

CREATE TABLE IF NOT EXISTS reviews (
    review_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_id BIGINT REFERENCES orders(order_id) ON DELETE SET NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(150),
    comment TEXT NOT NULL,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(30) NOT NULL DEFAULT 'APPROVED' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- INDEXES TỐI ƯU TRUY VẤN
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_products_slug ON products(slug);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_players ON products(min_players, max_players);
CREATE INDEX IF NOT EXISTS idx_products_playtime ON products(min_playtime, max_playtime);
CREATE INDEX IF NOT EXISTS idx_product_categories_cat ON product_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
