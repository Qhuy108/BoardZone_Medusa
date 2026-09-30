# 🎲 BoardZone - Nền tảng Thương mại Điện tử Board Game

> Dự án môn học: **Thiết kế Hệ thống Thương mại Điện tử (EC312)**

---

## 1. Giới thiệu Dự án
**BoardZone** là nền tảng thương mại điện tử chuyên biệt dành cho cộng đồng yêu thích Board Game (trò chơi cờ bàn). Hệ thống cung cấp trải nghiệm mua sắm tối ưu với bộ lọc đa chiều đặc thù (số người chơi, thời gian chơi, độ tuổi, thể loại/cơ chế game), hệ thống giỏ hàng, áp dụng voucher khuyến mãi, quản lý đơn hàng toàn trình và đánh giá sản phẩm sau mua.

---

## 2. Kiến trúc Hệ thống (System Architecture)

Dự án được xây dựng theo mô hình kiến trúc phân tán Headless Commerce:

- **Backend:** [MedusaJS v2](file:///c:/Users/User/BoardZone/boardzone-medusa) (Headless Commerce Engine hỗ trợ Modules, Workflows, Search Index, Pricing, Inventory & Multi-currency).
- **Frontend / Storefront:** [Next.js Storefront](file:///c:/Users/User/BoardZone/boardzone-storefront) (Giao diện mua sắm tối ưu SEO, Server-Side Rendering & tốc độ tải trang).
- **Cơ sở dữ liệu:** PostgreSQL (Triển khai trên **Supabase Cloud**) tương thích chuẩn 3NF và kiến trúc Medusa schema.

---

## 3. Tài liệu Kỹ thuật & Nghiệp vụ Dự án

Hệ thống đi kèm bộ tài liệu chi tiết:
1. 📄 **[DATABASE_DESIGN_BOARDZONE.md](file:///c:/Users/User/BoardZone/DATABASE_DESIGN_BOARDZONE.md)**: Đặc tả chi tiết 15 bảng dữ liệu (Data Dictionary), kiểu dữ liệu, ràng buộc khóa chính/ngoại và chỉ mục (Indexes).
2. 🔀 **[BUSINESS_WORKFLOWS_BOARDZONE.md](file:///c:/Users/User/BoardZone/BUSINESS_WORKFLOWS_BOARDZONE.md)**: Đặc tả 6 luồng nghiệp vụ cốt lõi kèm sơ đồ luồng (Flowchart) & biểu đồ tuần tự (Sequence Diagram).
3. 🗄️ **[boardzone_schema.sql](file:///c:/Users/User/BoardZone/boardzone_schema.sql)**: Script SQL DDL định nghĩa toàn bộ cấu trúc CSDL PostgreSQL.

---

## 4. Cấu trúc Thư mục Dự án

```
BoardZone/
├── boardzone-medusa/          # Backend API & Commerce Logic (MedusaJS v2)
│   ├── apps/backend/          # Mã nguồn Medusa Backend & Seed scripts
│   └── packages/              # Chứa các custom modules (nếu có)
├── boardzone-storefront/      # Frontend ứng dụng Storefront (Next.js 15)
├── boardzone_schema.sql       # Script DDL PostgreSQL CSDL 3NF
├── DATABASE_DESIGN_BOARDZONE.md # Tài liệu thiết kế CSDL chuẩn 3NF
├── BUSINESS_WORKFLOWS_BOARDZONE.md # Tài liệu các luồng nghiệp vụ chi tiết
├── .gitignore                 # Cấu hình bỏ qua dependencies, file môi trường
└── README.md                  # Tài liệu tổng quan & nhật ký triển khai
```

---

## 5. Dữ liệu Mẫu (Seed Data)
Hệ thống đã được thiết lập dữ liệu mẫu chuẩn ngành Board Game:

### Danh mục (Categories):
1. **Chiến thuật (Strategy)**: Catan, Splendor,...
2. **Party & Nhóm (Party Games)**: Ma Sói Ultimate, Mèo Nổ, Bang! The Dice Game,...
3. **Gia đình (Family)**: Uno Flip!,...
4. **Ẩn vai & Suy luận (Social Deduction & Bluffing)**: Ma Sói, Bang!,...

### Danh sách Sản phẩm mẫu đã nạp:
- 🐺 **Ma Sói Ultimate (Ultimate Werewolf)** — 250.000 VNĐ / 12 EUR (Biến thể: Bản Tiêu Chuẩn, Bản Mở Rộng Kèm Túi Nhung)
- 💣 **Mèo Nổ (Exploding Kittens)** — 180.000 VNĐ / 9 EUR (Biến thể: Bản Gốc Cơ Bản, Bản Mở Rộng NSFW)
- 🏝️ **Catan (The Settlers of Catan)** — 750.000 VNĐ / 38 EUR (Biến thể: Bản Tiếng Việt, Bản Quốc Tế Gốc)
- 🃏 **Uno Flip!** — 90.000 VNĐ / 4.5 EUR (Biến thể: Hộp Nhựa Chống Nước, Hộp Giấy Tiêu Chuẩn)
- 💎 **Splendor** — 550.000 VNĐ / 28 EUR (Biến thể: Bản Quốc Tế Chip Nặng)
- 🤠 **Bang! The Dice Game** — 320.000 VNĐ / 16 EUR (Biến thể: Bản Xúc Xắc Tiêu Chuẩn)

---

## 6. Hướng dẫn Chạy Thử nghiệm (Quick Start)

### 1. Backend (Medusa v2):
```bash
cd boardzone-medusa/apps/backend
npm run dev
```
- **Backend API:** `http://localhost:9000`
- **Admin Dashboard:** `http://localhost:9000/app`
- **Tài khoản Quản trị (Admin):**
  - **Email:** `admin@boardzone.com`
  - **Mật khẩu:** `Admin@123456`

### 2. Storefront (Next.js):
```bash
cd boardzone-storefront
npm run dev
```
- **Storefront URL:** `http://localhost:8000` (hoặc `http://localhost:3000`)
- **Store Danh mục:** `http://localhost:8000/dk/store`
- **Publishable API Key:** Đã liên kết tự động trong `boardzone-storefront/.env.local`.

---

## 7. Nhật ký Công việc đã Thực hiện (Changelog / Execution Log)
- [x] Thiết kế mô hình CSDL chuẩn 3NF cho dự án Board Game (15 bảng) & tạo file `DATABASE_DESIGN_BOARDZONE.md`.
- [x] Xây dựng tài liệu 6 luồng nghiệp vụ cốt lõi kèm Mermaid Diagram trong `BUSINESS_WORKFLOWS_BOARDZONE.md`.
- [x] Kết nối và đồng bộ CSDL với **Supabase Cloud PostgreSQL**.
- [x] Đẩy toàn bộ mã nguồn ban đầu lên kho lưu trữ GitHub `Qhuy108/BoardZone_Medusa`.
- [x] Khởi tạo tài khoản Quản trị Admin Dashboard (`admin@boardzone.com`).
- [x] Dọn dẹp các sản phẩm quần áo demo mặc định.
- [x] Tạo danh mục Board Game và nạp các sản phẩm Board Game thực tế kèm biến thể & giá đa tiền tệ.
- [x] Tạo và trích xuất Publishable API Key từ Medusa Backend sang cấu hình Storefront `.env.local`.
- [x] Khởi chạy và kiểm tra hoạt động của cả Backend Medusa và Frontend Next.js Storefront.

