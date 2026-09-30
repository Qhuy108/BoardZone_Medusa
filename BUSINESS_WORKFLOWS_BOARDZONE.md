# TÀI LIỆU CÁC LUỒNG NGHIỆP VỤ HỆ THỐNG BOARDZONE (EC312)

Tài liệu này đặc tả chi tiết toàn bộ các luồng nghiệp vụ (Business Workflows) chính của hệ thống thương mại điện tử chuyên biệt về Board Game – **BoardZone**, bao gồm sơ đồ luồng (Flowchart), biểu đồ tuần tự (Sequence Diagram), các bước xử lý và tác động tới cơ sở dữ liệu tương ứng.

---

## MỤC LỤC

1. [Tổng quan các tác nhân (Actors) trong hệ thống](#1-tong-quan-cac-tac-nhan-actors-trong-he-thong)
2. [Luồng 1: Xác thực & Quản lý Tài khoản (Authentication & Account)](#luong-1-xac-thuc--quan-ly-tai-khoan-authentication--account)
3. [Luồng 2: Khám phá & Lọc Sản phẩm Board Game đa chiều](#luong-2-kham-pha--loc-san-pham-board-game-da-chieu)
4. [Luồng 3: Quản lý Giỏ hàng & Áp dụng Mã giảm giá (Cart & Coupon)](#luong-3-quan-ly-gio-hang--ap-dung-ma-giam-gia-cart--coupon)
5. [Luồng 4: Quy trình Đặt hàng & Thanh toán (Checkout & Payment)](#luong-4-quy-trinh-dat-hang--thanh-toan-checkout--payment)
6. [Luồng 5: Xử lý Đơn hàng & Quản lý Kho (Order Fulfillment & Inventory)](#luong-5-xu-ly-don-hang--quan-ly-kho-order-fulfillment--inventory)
7. [Luồng 6: Đánh giá & Phản hồi sau mua (Verified Review Flow)](#luong-6-danh-gia--phan-hoi-sau-mua-verified-review-flow)
8. [Bảng tổng hợp Ma trận Phân quyền & Tác động Dữ liệu](#8-bang-tong-hop-ma-tran-phan-quyen--tac-dong-du-lieu)

---

## 1. Tổng quan các tác nhân (Actors) trong hệ thống

- **Khách vãng lai (Guest):** Người dùng chưa đăng nhập, có thể duyệt xem sản phẩm, tìm kiếm, lọc theo thuộc tính game và tạo giỏ hàng tạm.
- **Khách hàng (Customer):** Người dùng đã đăng ký/đăng nhập tài khoản, quản lý địa chỉ nhận hàng, đặt hàng, theo dõi tiến trình đơn hàng và viết đánh giá sản phẩm đã mua.
- **Nhân viên bán hàng / Xử lý đơn (Staff):** Xác nhận đơn hàng, kiểm tra thanh toán, cập nhật trạng thái đóng gói và bàn giao giao vận.
- **Quản lý kho (Warehouse Manager):** Quản lý số lượng tồn kho (stock), nhập hàng, cập nhật SKU và thông số game.
- **Quản trị viên (Admin):** Quản lý toàn diện hệ thống: tài khoản nhân viên, danh mục, sản phẩm, chiến dịch khuyến mãi (Coupons) và duyệt đánh giá.

---

## Luồng 1: Xác thực & Quản lý Tài khoản (Authentication & Account)

### 1.1. Sơ đồ tuần tự Đăng ký & Đăng nhập Khách hàng

```mermaid
sequenceDiagram
    autonumber
    actor C as Khách hàng
    participant FE as Storefront UI
    participant BE as Backend API / Auth
    participant DB as Supabase PostgreSQL

    %% Đăng ký
    Note over C, DB: Quy trình Đăng ký tài khoản
    C->>FE: Nhập Email, Họ tên, Mật khẩu
    FE->>BE: POST /api/auth/register
    BE->>DB: Kiểm tra Email trong bảng `customers`
    alt Email đã tồn tại
        DB-->>BE: Đã tồn tại
        BE-->>FE: Báo lỗi "Email đã được sử dụng"
    else Email hợp lệ
        BE->>BE: Băm mật khẩu (Hash password - Bcrypt/Argon2)
        BE->>DB: INSERT INTO customers (email, password_hash, full_name)
        DB-->>BE: Tạo thành công (customer_id)
        BE-->>FE: Trả về Access Token + User Info
        FE-->>C: Thông báo đăng ký thành công & Tự động đăng nhập
    end

    %% Quản lý sổ địa chỉ
    Note over C, DB: Thêm địa chỉ giao hàng
    C->>FE: Nhập địa chỉ nhận hàng mới
    FE->>BE: POST /api/customer/addresses (kèm JWT)
    BE->>DB: INSERT INTO customer_addresses (customer_id, receiver_name, receiver_phone, street_address, ward, district, province, is_default)
    DB-->>BE: Trả về address_id
    BE-->>FE: Cập nhật danh sách địa chỉ nhận hàng
```

### 1.2. Các bảng CSDL tham gia
- `public.customers`
- `public.customer_addresses`
- `public.users` (dành riêng cho phân quyền nội bộ Admin/Staff)

---

## Luồng 2: Khám phá & Lọc Sản phẩm Board Game đa chiều

Khác với các mặt hàng thông thường, Board Game đòi hỏi bộ lọc đặc thù chuyên sâu nhằm giúp người chơi nhanh chóng tìm thấy tựa game phù hợp với nhóm của mình.

### 2.1. Sơ đồ xử lý Lọc & Tìm kiếm Board Game

```mermaid
flowchart TD
    Start([Khách truy cập Trang Cửa hàng]) --> FilterInput[Khách chọn các tiêu chí lọc]
    
    subgraph TieuChiLoc [Bộ lọc đặc thù Board Game]
        F1[Số lượng người chơi: min_players <= X <= max_players]
        F2[Thời gian chơi: min_playtime / max_playtime]
        F3[Thể loại / Cơ chế: categories / product_categories]
        F4[Độ tuổi khuyến nghị: min_age]
        F5[Khoảng giá: price BETWEEN min AND max]
    end
    
    FilterInput --> TieuChiLoc
    TieuChiLoc --> APIQuery[Frontend gửi Query Parameters về Backend]
    APIQuery --> DBSearch[Truy vấn PostgreSQL tối ưu bằng Indexes]
    
    DBSearch --> CheckResult{Có kết quả?}
    CheckResult -- Có --> RenderList[Hiển thị thẻ Board Game: Tên, Thumbnail, Giá, Số người chơi, Thời gian, Badge Thể loại]
    CheckResult -- Không --> RenderEmpty[Hiển thị gợi ý: Đổi bộ lọc hoặc tìm game tương tự]
    
    RenderList --> ViewDetail[Khách click xem chi tiết 1 Board Game]
    ViewDetail --> FetchDetail[Truy vấn products + product_images + categories + reviews đã duyệt]
    FetchDetail --> RenderDetail[Hiển thị chi tiết: Cốt truyện, Thành phần hộp, Luật chơi vắn tắt, Đánh giá sao]
```

### 2.2. Các bảng CSDL tham gia
- `public.products` (lọc nhanh nhờ `idx_products_players`, `idx_products_playtime`, `idx_products_price`)
- `public.categories`
- `public.product_categories`
- `public.product_images`
- `public.reviews`

---

## Luồng 3: Quản lý Giỏ hàng & Áp dụng Mã giảm giá (Cart & Coupon)

### 3.1. Sơ đồ tuần tự Thêm vào giỏ & Áp mã Voucher

```mermaid
sequenceDiagram
    autonumber
    actor C as Khách hàng / Khách vãng lai
    participant FE as Storefront UI
    participant BE as Backend API
    participant DB as Supabase PostgreSQL

    C->>FE: Nhấn "Thêm vào giỏ hàng" (product_id, quantity)
    FE->>BE: POST /api/cart/items (kèm session_token hoặc customer_id)
    BE->>DB: SELECT stock_quantity FROM products WHERE product_id = X
    alt Tồn kho không đủ (stock_quantity < quantity)
        DB-->>BE: Trả về tồn kho hiện tại
        BE-->>FE: Báo lỗi "Số lượng sản phẩm trong kho không đủ"
    else Tồn kho hợp lệ
        BE->>DB: INSERT/UPDATE cart_items (cart_id, product_id, quantity)
        DB-->>BE: Cập nhật thành công
        BE-->>FE: Trả về giỏ hàng mới nhất
        FE-->>C: Cập nhật số lượng trên icon Giỏ hàng
    end

    %% Áp dụng Voucher
    Note over C, DB: Khách nhập Mã giảm giá tại Giỏ hàng
    C->>FE: Nhập mã Coupon (vd: "BOARDGAME10")
    FE->>BE: POST /api/coupons/validate (code, subtotal)
    BE->>DB: SELECT * FROM coupons WHERE code = 'BOARDGAME10' AND is_active = TRUE
    alt Mã không tồn tại hoặc Hết hạn (CURRENT_TIMESTAMP NOT BETWEEN start_date AND end_date)
        BE-->>FE: Báo lỗi "Mã giảm giá không hợp lệ hoặc đã hết hạn"
    else Chưa đạt giá trị đơn tối thiểu (subtotal < min_order_value)
        BE-->>FE: Báo lỗi "Đơn hàng chưa đạt giá trị tối thiểu để áp dụng mã"
    else Hết lượt sử dụng (used_count >= usage_limit)
        BE-->>FE: Báo lỗi "Mã giảm giá đã hết lượt sử dụng"
    else Hợp lệ
        BE->>BE: Tính toán số tiền giảm (discount_amount)
        BE-->>FE: Trả về: discount_amount & total_amount tạm tính
        FE-->>C: Hiển thị tiền giảm & Giá trị thanh toán mới
    end
```

### 3.2. Các bảng CSDL tham gia
- `public.carts`
- `public.cart_items`
- `public.products`
- `public.coupons`

---

## Luồng 4: Quy trình Đặt hàng & Thanh toán (Checkout & Payment)

### 4.1. Sơ đồ xử lý Đặt hàng (Checkout Flow)

```mermaid
flowchart TD
    Start([Khách nhấn Tiến hành Thanh toán]) --> Step1[Chọn/Nhập Địa chỉ giao hàng & SĐT]
    Step1 --> Step2[Chọn Phương thức Thanh toán: COD / VNPAY / MOMO / BANK_TRANSFER]
    Step2 --> Step3[Kiểm tra lại Đơn hàng & Mã giảm giá]
    Step3 --> SubmitOrder[Khách nhấn 'Đặt hàng ngay']
    
    SubmitOrder --> DBTransaction[Bắt đầu Database Transaction]
    
    subgraph DB_Action [Xử lý trong Transaction]
        T1[1. Khóa & Kiểm tra tồn kho các sản phẩm trong giỏ hàng]
        T2[2. Tạo bản ghi `orders` với order_status = 'PENDING']
        T3[3. Tạo các dòng `order_items` lưu snapshot unit_price & product_name_snap]
        T4[4. Trừ tồn kho `products.stock_quantity -= quantity`]
        T5[5. Tăng lượt dùng voucher `coupons.used_count += 1`]
        T6[6. Tạo bản ghi `payments` trạng thái PENDING]
        T7[7. Ghi lịch sử `order_status_history` trạng thái PENDING]
        T8[8. Xóa các sản phẩm đã đặt khỏi `cart_items`]
    end
    
    DBTransaction --> DB_Action
    DB_Action --> CheckPaymentType{Phương thức thanh toán?}
    
    CheckPaymentType -- COD / Chuyển khoản thủ công --> OrderSuccess[Hoàn tất đặt hàng -> Chuyển đến trang Cảm ơn & Gửi email xác nhận]
    
    CheckPaymentType -- Cổng thanh toán Online (VNPAY/MOMO) --> RedirectGateway[Chuyển hướng sang Cổng thanh toán VNPAY/MOMO]
    RedirectGateway --> PaymentProcess[Khách quét mã / Nhập thẻ thanh toán]
    
    PaymentProcess --> IPNCallback[Cổng thanh toán gọi Webhook/IPN về Backend]
    IPNCallback --> CheckIPN{Thanh toán thành công?}
    
    CheckIPN -- Thành công --> UpdatePaymentSuccess[Cập nhật `payments.payment_status = 'SUCCESS'`, `orders.order_status = 'CONFIRMED'`]
    CheckIPN -- Thất bại --> UpdatePaymentFail[`payments.payment_status = 'FAILED'`, giữ đơn chờ xử lý hoặc hủy]
```

### 4.2. Các bảng CSDL tham gia
- `public.orders`
- `public.order_items` (lưu **snapshot** bảo vệ toàn vẹn lịch sử giao dịch khi giá sản phẩm gốc thay đổi)
- `public.payments`
- `public.order_status_history`
- `public.products`
- `public.coupons`
- `public.cart_items`

---

## Luồng 5: Xử lý Đơn hàng & Quản lý Kho (Order Fulfillment & Inventory)

### 5.1. Vòng đời Trạng thái Đơn hàng (Order State Machine)

```mermaid
stateDiagram-v2
    [*] --> PENDING: Khách đặt hàng thành công
    
    PENDING --> CONFIRMED: Nhân viên xác nhận / Thanh toán Online thành công
    PENDING --> CANCELLED: Khách hủy đơn / Quá hạn thanh toán
    
    CONFIRMED --> PROCESSING: Thủ kho đóng gói & in vận đơn
    CONFIRMED --> CANCELLED: Khách yêu cầu hủy đơn trước khi gửi
    
    PROCESSING --> SHIPPING: Bàn giao bưu tá / đơn vị vận chuyển
    
    SHIPPING --> COMPLETED: Giao hàng thành công & Thu tiền (nếu COD)
    SHIPPING --> CANCELLED: Giao không thành công / Khách từ chối nhận (Hoàn hàng)
    
    CANCELLED --> [*]: Tự động hoàn lại stock_quantity vào kho
    COMPLETED --> [*]: Mở quyền Đánh giá sản phẩm (Verified Purchase)
```

### 5.2. Các bước tác động dữ liệu khi Đơn hàng thay đổi trạng thái
1. **Chuyển sang `PROCESSING` / `SHIPPING`:**
   - Nhân viên cập nhật trên Dashboard Quản trị.
   - Thêm bản ghi vào `order_status_history` ghi lại `changed_by_user_id`, `status_from`, `status_to`, thời điểm và ghi chú giao vận.
2. **Khi đơn hàng bị HỦY (`CANCELLED`):**
   - Hệ thống tự động hoàn lại tồn kho: `UPDATE products SET stock_quantity = stock_quantity + quantity`.
   - Nếu có dùng voucher: giảm lượt dùng `UPDATE coupons SET used_count = used_count - 1`.
   - Ghi nhận lịch sử hủy vào `order_status_history`.

---

## Luồng 6: Đánh giá & Phản hồi sau mua (Verified Review Flow)

Nhằm đảm bảo tính khách quan và uy tín cho cộng đồng chơi Board Game, hệ thống ưu tiên các nhận xét từ người đã thực sự mua hàng.

### 6.1. Sơ đồ tuần tự Đánh giá sản phẩm

```mermaid
sequenceDiagram
    autonumber
    actor C as Khách hàng
    participant FE as Storefront UI
    participant BE as Backend API
    participant DB as Supabase PostgreSQL

    C->>FE: Vào trang chi tiết Board Game đã mua -> Bấm "Viết đánh giá"
    FE->>BE: GET /api/reviews/check-purchased (product_id, customer_id)
    BE->>DB: Kiểm tra đơn hàng có `product_id` ở trạng thái `COMPLETED`
    alt Đã mua hàng thành công
        DB-->>BE: Trả về order_id hợp lệ
        BE-->>FE: Cho phép đánh giá với nhãn "Verified Purchase"
    else Chưa mua sản phẩm này
        DB-->>BE: Không tìm thấy đơn COMPLETED
        BE-->>FE: Cho phép đánh giá cộng đồng thông thường (is_verified = FALSE)
    end

    C->>FE: Nhập số sao (1-5), tiêu đề, nội dung trải nghiệm board game -> Bấm Gửi
    FE->>BE: POST /api/reviews (product_id, rating, title, comment, order_id)
    BE->>DB: INSERT INTO reviews (product_id, customer_id, order_id, rating, title, comment, is_verified_purchase, status)
    DB-->>BE: Lưu thành công (review_id)
    BE-->>FE: Thông báo "Đánh giá của bạn đã được ghi nhận!"
    FE-->>C: Hiển thị đánh giá trên trang chi tiết Board Game
```

---

## 8. Bảng tổng hợp Ma trận Phân quyền & Tác động Dữ liệu

| Phân hệ / Bảng dữ liệu | Khách vãng lai (Guest) | Khách hàng (Customer) | Nhân viên (Staff) | Quản lý kho (Warehouse) | Quản trị viên (Admin) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`products`, `categories`** | Chỉ Đọc (Xem/Lọc) | Chỉ Đọc (Xem/Lọc) | Chỉ Đọc | Đọc / Cập nhật tồn kho | Toàn quyền (CRUD) |
| **`carts`, `cart_items`** | Tạo/Sửa (Session) | Tạo/Sửa (User ID) | Không | Không | Xem báo cáo |
| **`coupons`** | Nhập áp dụng | Nhập áp dụng | Tra cứu mã | Không | Toàn quyền (Tạo/Sửa) |
| **`orders`, `order_items`** | Không | Tạo đơn / Xem đơn của mình | Duyệt đơn / Cập nhật trạng thái | Xem để xuất kho | Toàn quyền |
| **`payments`** | Không | Khởi tạo khi checkout | Đối soát giao dịch | Không | Toàn quyền |
| **`reviews`** | Chỉ Đọc | Viết nhận xét game | Ẩn review vi phạm | Không | Kiểm duyệt / Xóa |
| **`users`** | Không | Không | Xem thông tin cá nhân | Xem thông tin cá nhân | Toàn quyền quản trị nhân sự |
