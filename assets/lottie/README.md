# Lottie animations

Thả file `.json` (export từ After Effects / LottieFiles) vào đúng thư mục:

| Thư mục | Mục đích |
|---------|----------|
| `common/` | Dùng chung toàn app |
| `loading/` | Loading, AI đang phân tích |
| `empty/` | Trạng thái rỗng |
| `success/` | Thanh toán / hoàn tất |
| `error/` | Lỗi, thất bại |
| `tenant/` | Màn hình cư dân |
| `manager/` | Màn hình quản lý |

Sau khi thêm file mới, khai báo path trong `lib/core/lottie/lottie_assets.dart`.
