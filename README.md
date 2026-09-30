# 🎲 BoardZone - Nền tảng Thương mại Điện tử Board Game

> Dự án môn học: **Thiết kế Hệ thống Thương mại Điện tử (EC312)**

---

## 1. Giới thiệu Dự án
**BoardZone** là nền tảng thương mại điện tử chuyên biệt dành cho cộng đồng yêu thích Board Game (trò chơi cờ bàn). Hệ thống cung cấp trải nghiệm mua sắm tối ưu với bộ lọc đa chiều đặc thù (số người chơi, thời gian chơi, độ tuổi, thể loại/cơ chế game), hệ thống giỏ hàng, áp dụng voucher khuyến mãi, quản lý đơn hàng toàn trình và đánh giá sản phẩm sau mua.

---

## 2. Kiến trúc Hệ thống (System Architecture)

Dự án được xây dựng theo mô hình kiến trúc phân tán / monorepo:

- **Backend:** [MedusaJS](file:///c:/Users/User/BoardZone/boardzone-medusa) (Headless Commerce Engine).
- **Frontend / Storefront:** [Next.js Storefront](file:///c:/Users/User/BoardZone/boardzone-storefront) (Giao diện mua sắm tối ưu SEO & tốc độ tải trang).
- **Cơ sở dữ liệu:** PostgreSQL (Triển khai trên **Supabase Cloud**) đạt chuẩn chuẩn hóa bậc 3 (3NF).

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
├── boardzone-medusa/          # Backend API & Commerce Logic (MedusaJS)
├── boardzone-storefront/      # Frontend ứng dụng Storefront (Next.js)
├── boardzone_schema.sql       # Script DDL PostgreSQL CSDL
├── DATABASE_DESIGN_BOARDZONE.md # Tài liệu thiết kế CSDL chuẩn 3NF
├── BUSINESS_WORKFLOWS_BOARDZONE.md # Tài liệu các luồng nghiệp vụ
├── .gitignore                 # Cấu hình bỏ qua dependencies, file môi trường
└── README.md                  # Tài liệu tổng quan dự án
```

---

## 5. Hướng dẫn Chạy Thử nghiệm (Quick Start)

### Backend (Medusa):
```bash
cd boardzone-medusa/apps/backend
npm install
npm run dev
```

### Storefront (Next.js):
```bash
cd boardzone-storefront
npm install
npm run dev
```
Truy cập: `http://localhost:8000` (Backend) | `http://localhost:3000` (Storefront).
