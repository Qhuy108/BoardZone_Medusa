# TÀI LIỆU HỆ THỐNG THƯƠNG MẠI ĐIỆN TỬ BOARDZONE (EC312)

## 1. Giới thiệu dự án
- **Tên dự án:** BoardZone
- **Mục tiêu:** Xây dựng nền tảng thương mại điện tử chuyên biệt kinh doanh các sản phẩm Board Game (trò chơi cờ bàn).
- **Môn học:** Thiết kế hệ thống Thương mại điện tử (EC312).
- **Hệ quản trị CSDL:** PostgreSQL.
- **Mục tiêu kiến trúc:** Chuẩn hóa dữ liệu bậc 3 (3NF), tối ưu cho truy vấn lọc đa chiều theo đặc thù board game (số người chơi, thời gian, độ tuổi, thể loại), tích hợp giỏ hàng, khuyến mãi, đánh giá và phân quyền quản trị.

---

## 2. Kiến trúc & Phân hệ CSDL (Database Schema Architecture)

Hệ thống cơ sở dữ liệu BoardZone được phân chia thành 6 phân hệ cốt lõi:

```
[1. User & Customer Management]  ──>  [2. Product & Category (N-N)]
             │                                      │
             ├──> [3. Cart & CartItem]              │
             │           │                          │
             │           ▼                          │
             ├──> [4. Order & OrderItem] <──────────┘
             │           │              ▲
             │           ▼              │
             ├──> [5. Payment]     [4.1. Coupons / Vouchers]
             │
             └──> [6. Product Reviews & Ratings (Verified Purchase)]
```

---

## 3. Đặc tả chi tiết các bảng dữ liệu (Data Dictionary)

### 3.1. Phân hệ Quản lý Tài khoản & Phân quyền

#### Bảng `users` (Quản trị viên & Nhân viên)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `user_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Định danh người dùng nội bộ hệ thống |
| `email` | `VARCHAR(150)` | **UNIQUE** | NOT NULL | Email đăng nhập quản trị |
| `password_hash` | `VARCHAR(255)` | | NOT NULL | Mật khẩu băm an toàn (bcrypt/argon2) |
| `full_name` | `VARCHAR(100)` | | NOT NULL | Họ và tên nhân viên / admin |
| `role` | `VARCHAR(50)` | | NOT NULL, DEFAULT 'STAFF' | Quyền hạn: `ADMIN`, `STAFF`, `WAREHOUSE` |
| `is_active` | `BOOLEAN` | | NOT NULL, DEFAULT TRUE | Trạng thái hoạt động tài khoản |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày tạo tài khoản |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày cập nhật gần nhất |

#### Bảng `customers` (Khách hàng)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `customer_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã định danh duy nhất của khách hàng |
| `email` | `VARCHAR(150)` | **UNIQUE** | NOT NULL | Email dùng đăng nhập và nhận hóa đơn |
| `password_hash` | `VARCHAR(255)` | | NOT NULL | Mật khẩu tài khoản đã mã hóa |
| `full_name` | `VARCHAR(100)` | | NOT NULL | Họ và tên đầy đủ của khách hàng |
| `phone_number` | `VARCHAR(20)` | | NULL | Số điện thoại liên hệ |
| `avatar_url` | `VARCHAR(255)` | | NULL | Ảnh đại diện khách hàng |
| `is_active` | `BOOLEAN` | | DEFAULT TRUE | Khóa/Mở tài khoản khách |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian đăng ký |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian cập nhật |

#### Bảng `customer_addresses` (Sổ địa chỉ khách hàng)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `address_id` | `SERIAL` | **PK** | NOT NULL | Mã địa chỉ |
| `customer_id` | `INT` / `BIGINT` | **FK** | REFERENCES customers(customer_id) ON DELETE CASCADE | Khách hàng sở hữu địa chỉ |
| `receiver_name` | `VARCHAR(100)` | | NOT NULL | Tên người nhận hàng |
| `receiver_phone` | `VARCHAR(20)` | | NOT NULL | Số điện thoại người nhận |
| `street_address` | `VARCHAR(255)` | | NOT NULL | Địa chỉ chi tiết (số nhà, tên đường) |
| `ward` | `VARCHAR(100)` | | NOT NULL | Phường / Xã |
| `district` | `VARCHAR(100)` | | NOT NULL | Quận / Huyện |
| `province` | `VARCHAR(100)` | | NOT NULL | Tỉnh / Thành phố |
| `is_default` | `BOOLEAN` | | DEFAULT FALSE | Đặt làm địa chỉ mặc định |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày tạo |

---

### 3.2. Phân hệ Danh mục & Sản phẩm Board Game (N - N)

#### Bảng `categories` (Thể loại & Cơ chế game)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `category_id` | `SERIAL` | **PK** | NOT NULL | Mã danh mục |
| `category_name` | `VARCHAR(100)` | | NOT NULL | Tên thể loại (Chiến thuật, Party, Gia đình...) |
| `slug` | `VARCHAR(150)` | **UNIQUE** | NOT NULL | Đường dẫn thân thiện (SEO friendly slug) |
| `description` | `TEXT` | | NULL | Mô tả chi tiết về thể loại |
| `parent_id` | `INT` | **FK** | REFERENCES categories(category_id) ON DELETE SET NULL | Hỗ trợ phân cấp danh mục cha - con |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày tạo |

#### Bảng `products` (Sản phẩm Board Game)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `product_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã sản phẩm |
| `sku` | `VARCHAR(50)` | **UNIQUE** | NOT NULL | Mã quản lý kho hàng |
| `product_name` | `VARCHAR(200)` | | NOT NULL | Tên thương mại của Board Game |
| `slug` | `VARCHAR(250)` | **UNIQUE** | NOT NULL | URL định danh sản phẩm |
| `description` | `TEXT` | | NULL | Mô tả luật chơi, cốt truyện, chi tiết phụ kiện |
| `short_description` | `VARCHAR(500)` | | NULL | Tóm tắt nhanh hiển thị trên danh sách thẻ game |
| `price` | `NUMERIC(12,2)` | | NOT NULL, CHECK (price >= 0) | Giá bán hiện tại |
| `original_price` | `NUMERIC(12,2)` | | NULL | Giá niêm yết gốc (dùng hiển thị giảm giá) |
| `stock_quantity` | `INT` | | NOT NULL, DEFAULT 0, CHECK (stock_quantity >= 0) | Số lượng tồn kho |
| `min_players` | `INT` | | NOT NULL, CHECK (min_players > 0) | Số người chơi tối thiểu |
| `max_players` | `INT` | | NOT NULL, CHECK (max_players >= min_players) | Số người chơi tối đa |
| `min_playtime` | `INT` | | NULL, CHECK (min_playtime > 0) | Thời gian chơi tối thiểu (phút) |
| `max_playtime` | `INT` | | NULL, CHECK (max_playtime >= min_playtime) | Thời gian chơi tối đa (phút) |
| `min_age` | `INT` | | NULL, CHECK (min_age >= 0) | Độ tuổi khuyến nghị tối thiểu |
| `publisher` | `VARCHAR(150)` | | NULL | Nhà xuất bản (Days of Wonder, Stonemaier...) |
| `designer` | `VARCHAR(150)` | | NULL | Tác giả thiết kế game |
| `language` | `VARCHAR(50)` | | DEFAULT 'Tiếng Việt' | Ngôn ngữ phiên bản (Việt hóa, Tiếng Anh, Song ngữ) |
| `thumbnail_url` | `VARCHAR(255)` | | NULL | Ảnh đại diện chính của sản phẩm |
| `is_active` | `BOOLEAN` | | DEFAULT TRUE | Ẩn/Hiện sản phẩm trên website |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm tạo |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm cập nhật |

#### Bảng `product_categories` (Liên kết Nhiều - Nhiều giữa Product và Category)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `product_id` | `INT` / `BIGINT` | **PK, FK** | REFERENCES products(product_id) ON DELETE CASCADE | Mã sản phẩm |
| `category_id` | `INT` | **PK, FK** | REFERENCES categories(category_id) ON DELETE CASCADE | Mã danh mục |

#### Bảng `product_images` (Bộ sưu tập hình ảnh chi tiết)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `image_id` | `SERIAL` | **PK** | NOT NULL | Mã ảnh |
| `product_id` | `INT` / `BIGINT` | **FK** | REFERENCES products(product_id) ON DELETE CASCADE | Sản phẩm tương ứng |
| `image_url` | `VARCHAR(255)` | | NOT NULL | Đường dẫn ảnh CDN/Storage |
| `display_order` | `INT` | | DEFAULT 0 | Thứ tự hiển thị hình ảnh |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày tải lên |

---

### 3.3. Phân hệ Giỏ hàng (Cart)

#### Bảng `carts` (Giỏ hàng)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `cart_id` | `UUID` / `BIGSERIAL` | **PK** | NOT NULL | Mã định danh giỏ hàng |
| `customer_id` | `INT` / `BIGINT` | **FK** | REFERENCES customers(customer_id) ON DELETE CASCADE, NULLABLE | Khách hàng đã đăng nhập |
| `session_token` | `VARCHAR(255)` | **UNIQUE** | NULLABLE | Dành cho khách vãng lai chưa đăng nhập |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm tạo |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm cập nhật giỏ hàng |

#### Bảng `cart_items` (Món hàng trong giỏ)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `cart_item_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã dòng trong giỏ |
| `cart_id` | `UUID` / `BIGINT` | **FK** | REFERENCES carts(cart_id) ON DELETE CASCADE | Thuộc giỏ hàng nào |
| `product_id` | `INT` / `BIGINT` | **FK** | REFERENCES products(product_id) ON DELETE CASCADE | Sản phẩm trong giỏ |
| `quantity` | `INT` | | NOT NULL, DEFAULT 1, CHECK (quantity > 0) | Số lượng chọn mua |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày thêm vào |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày sửa số lượng |

---

### 3.4. Phân hệ Khuyến mãi & Giảm giá (Coupons)

#### Bảng `coupons` (Mã giảm giá)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `coupon_id` | `SERIAL` | **PK** | NOT NULL | Mã voucher |
| `code` | `VARCHAR(50)` | **UNIQUE** | NOT NULL | Mã code người dùng nhập (vd: `BOARDGAME10`, `FREESHIP`) |
| `discount_type` | `VARCHAR(20)` | | NOT NULL | `PERCENTAGE` (theo %) hoặc `FIXED_AMOUNT` (tiền cố định) |
| `discount_value` | `NUMERIC(12,2)` | | NOT NULL, CHECK (discount_value > 0) | Giá trị giảm |
| `min_order_value`| `NUMERIC(12,2)` | | DEFAULT 0 | Giá trị đơn hàng tối thiểu để áp dụng |
| `max_discount_amount`| `NUMERIC(12,2)` | | NULL | Giới hạn tiền giảm tối đa (với mã %) |
| `usage_limit` | `INT` | | NULL | Tổng lượt dùng tối đa |
| `used_count` | `INT` | | DEFAULT 0 | Số lượt đã sử dụng |
| `start_date` | `TIMESTAMP WITH TIME ZONE` | | NOT NULL | Thời gian bắt đầu áp dụng |
| `end_date` | `TIMESTAMP WITH TIME ZONE` | | NOT NULL, CHECK (end_date > start_date) | Thời gian hết hạn |
| `is_active` | `BOOLEAN` | | DEFAULT TRUE | Trạng thái kích hoạt |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Ngày tạo mã |

---

### 3.5. Phân hệ Đơn hàng & Thanh toán (Orders & Payments)

#### Bảng `orders` (Đơn hàng)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `order_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã đơn hàng nội bộ |
| `order_code` | `VARCHAR(30)` | **UNIQUE** | NOT NULL | Mã đơn hàng đối ngoại (vd: `BZ20260930-001`) |
| `customer_id` | `INT` / `BIGINT` | **FK** | REFERENCES customers(customer_id) | Khách hàng đặt mua |
| `coupon_id` | `INT` | **FK** | REFERENCES coupons(coupon_id) ON DELETE SET NULL, NULLABLE | Voucher áp dụng |
| `order_status` | `VARCHAR(50)` | | NOT NULL, DEFAULT 'PENDING' | Trạng thái: `PENDING`, `CONFIRMED`, `PROCESSING`, `SHIPPING`, `COMPLETED`, `CANCELLED` |
| `subtotal_amount`| `NUMERIC(12,2)` | | NOT NULL, CHECK (subtotal_amount >= 0) | Tổng tiền hàng ban đầu |
| `discount_amount`| `NUMERIC(12,2)` | | NOT NULL, DEFAULT 0, CHECK (discount_amount >= 0) | Số tiền được giảm giá |
| `shipping_fee` | `NUMERIC(12,2)` | | NOT NULL, DEFAULT 0, CHECK (shipping_fee >= 0) | Phí vận chuyển |
| `total_amount` | `NUMERIC(12,2)` | | NOT NULL, CHECK (total_amount >= 0) | Tổng tiền thanh toán cuối cùng |
| `shipping_full_name`| `VARCHAR(100)` | | NOT NULL | Tên người nhận hàng |
| `shipping_phone` | `VARCHAR(20)` | | NOT NULL | Số điện thoại nhận hàng |
| `shipping_address`| `TEXT` | | NOT NULL | Địa chỉ giao hàng đầy đủ lúc đặt |
| `customer_note` | `TEXT` | | NULL | Ghi chú từ khách hàng |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian đặt hàng |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian cập nhật trạng thái |

#### Bảng `order_items` (Chi tiết món hàng trong đơn)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `order_item_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã dòng chi tiết |
| `order_id` | `INT` / `BIGINT` | **FK** | REFERENCES orders(order_id) ON DELETE CASCADE | Thuộc đơn hàng nào |
| `product_id` | `INT` / `BIGINT` | **FK** | REFERENCES products(product_id) | Sản phẩm mua |
| `product_name_snap`| `VARCHAR(200)` | | NOT NULL | Tên sản phẩm tại thời điểm mua (Snapshot) |
| `sku_snap` | `VARCHAR(50)` | | NOT NULL | SKU tại thời điểm mua (Snapshot) |
| `unit_price` | `NUMERIC(12,2)` | | NOT NULL, CHECK (unit_price >= 0) | Đơn giá tại thời điểm chốt đơn |
| `quantity` | `INT` | | NOT NULL, CHECK (quantity > 0) | Số lượng mua |
| `total_price` | `NUMERIC(12,2)` | | NOT NULL, CHECK (total_price >= 0) | Thành tiền (`unit_price * quantity`) |

#### Bảng `order_status_history` (Lịch sử trạng thái đơn hàng)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `history_id` | `SERIAL` | **PK** | NOT NULL | Mã bản ghi lịch sử |
| `order_id` | `INT` / `BIGINT` | **FK** | REFERENCES orders(order_id) ON DELETE CASCADE | Đơn hàng theo dõi |
| `status_from` | `VARCHAR(50)` | | NULL | Trạng thái trước |
| `status_to` | `VARCHAR(50)` | | NOT NULL | Trạng thái chuyển sang |
| `changed_by_user_id`| `INT` | **FK** | REFERENCES users(user_id) ON DELETE SET NULL, NULLABLE | Nhân viên thực hiện cập nhật |
| `note` | `TEXT` | | NULL | Ghi chú thay đổi (vd: Bàn giao cho bưu tá) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm ghi nhận |

#### Bảng `payments` (Giao dịch thanh toán)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `payment_id` | `SERIAL` / `BIGSERIAL` | **PK** | NOT NULL | Mã giao dịch thanh toán |
| `order_id` | `INT` / `BIGINT` | **FK** | REFERENCES orders(order_id) ON DELETE RESTRICT | Đơn hàng thanh toán |
| `payment_method`| `VARCHAR(50)` | | NOT NULL | Phương thức: `COD`, `VNPAY`, `MOMO`, `BANK_TRANSFER` |
| `transaction_id`| `VARCHAR(100)`| | NULL | Mã giao dịch từ cổng thanh toán đối soát |
| `amount` | `NUMERIC(12,2)` | | NOT NULL, CHECK (amount >= 0) | Số tiền thực tế giao dịch |
| `payment_status`| `VARCHAR(50)` | | NOT NULL, DEFAULT 'PENDING' | `PENDING`, `SUCCESS`, `FAILED`, `REFUNDED` |
| `payment_gateway_response` | `JSONB` | | NULL | Phản hồi webhook/payload gốc từ cổng thanh toán |
| `paid_at` | `TIMESTAMP WITH TIME ZONE` | | NULL | Thời điểm thanh toán thành công |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời điểm tạo giao dịch |

---

### 3.6. Phân hệ Đánh giá & Xếp hạng (Reviews & Ratings)

#### Bảng `reviews` (Nhận xét và chấm điểm sản phẩm)
| Tên cột | Kiểu dữ liệu | Khóa | Ràng buộc / Mặc định | Mô tả |
| :--- | :--- | :---: | :--- | :--- |
| `review_id` | `SERIAL` | **PK** | NOT NULL | Mã đánh giá |
| `product_id` | `INT` / `BIGINT` | **FK** | REFERENCES products(product_id) ON DELETE CASCADE | Game được đánh giá |
| `customer_id` | `INT` / `BIGINT` | **FK** | REFERENCES customers(customer_id) ON DELETE CASCADE | Khách hàng đánh giá |
| `order_id` | `INT` / `BIGINT` | **FK** | REFERENCES orders(order_id) ON DELETE SET NULL, NULLABLE | Đơn hàng đã mua (Verified Purchase) |
| `rating` | `INT` | | NOT NULL, CHECK (rating BETWEEN 1 AND 5) | Điểm số từ 1 đến 5 sao |
| `title` | `VARCHAR(150)` | | NULL | Tiêu đề ngắn của nhận xét |
| `comment` | `TEXT` | | NOT NULL | Nội dung chi tiết review gameplay/chất lượng |
| `is_verified_purchase`| `BOOLEAN` | | DEFAULT FALSE | Xác nhận người dùng đã thực sự mua sản phẩm |
| `status` | `VARCHAR(30)` | | DEFAULT 'APPROVED' | Trạng thái kiểm duyệt: `PENDING`, `APPROVED`, `REJECTED` |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian viết đánh giá |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | | DEFAULT CURRENT_TIMESTAMP | Thời gian cập nhật |

---

## 4. Bảng tổng hợp quan hệ (ERD Relationships Summary)

1. `users` 1 : N `order_status_history` (1 nhân viên có thể ghi nhận nhiều lần cập nhật trạng thái đơn).
2. `customers` 1 : N `customer_addresses` (1 khách hàng có nhiều địa chỉ giao nhận).
3. `customers` 1 : N `orders` (1 khách hàng đặt nhiều đơn hàng).
4. `customers` 1 : 1 `carts` (1 khách hàng sở hữu 1 giỏ hàng active).
5. `customers` 1 : N `reviews` (1 khách hàng viết nhiều đánh giá).
6. `categories` 1 : N `categories` (Quan hệ tự thân cha - con).
7. `products` N : N `categories` thông qua bảng trung gian `product_categories`.
8. `products` 1 : N `product_images` (1 board game có nhiều ảnh chi tiết).
9. `products` 1 : N `cart_items` (1 sản phẩm có trong nhiều giỏ hàng).
10. `products` 1 : N `order_items` (1 sản phẩm xuất hiện trong nhiều đơn hàng).
11. `products` 1 : N `reviews` (1 game nhận được nhiều đánh giá).
12. `carts` 1 : N `cart_items` (1 giỏ hàng chứa nhiều sản phẩm).
13. `coupons` 1 : N `orders` (1 mã giảm giá có thể áp dụng cho nhiều đơn).
14. `orders` 1 : N `order_items` (1 đơn hàng có nhiều dòng chi tiết sản phẩm).
15. `orders` 1 : N `payments` (1 đơn hàng có thể có các giao dịch thanh toán liên kết).
16. `orders` 1 : N `order_status_history` (1 đơn hàng lưu vết toàn bộ tiến trình xử lý).

---

## 5. Trạng thái Triển khai (Deployment Status)

- **Database:** Đã triển khai thành công 15 bảng và toàn bộ chỉ mục (Indexes) lên hệ quản trị CSDL Supabase PostgreSQL.
- **Danh sách bảng đã tạo:**
  1. `public.users`
  2. `public.customers`
  3. `public.customer_addresses`
  4. `public.categories`
  5. `public.products`
  6. `public.product_categories`
  7. `public.product_images`
  8. `public.carts`
  9. `public.cart_items`
  10. `public.coupons`
  11. `public.orders`
  12. `public.order_items`
  13. `public.order_status_history`
  14. `public.payments`
  15. `public.reviews`


