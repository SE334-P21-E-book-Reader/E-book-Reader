# Hướng dẫn cài đặt Firebase

## Cấu hình Firebase

1. Nhận file `google-services.json` từ quản trị viên dự án
2. Đặt file `google-services.json` vào thư mục `android/app/`
3. Không bao giờ commit file `google-services.json` vào repository

## Cấu trúc thư mục

```
android/
  └── app/
      └── google-services.json  <-- Đặt file ở đây
```

## Lưu ý bảo mật

- File `google-services.json` chứa thông tin nhạy cảm
- Chỉ chia sẻ file này qua kênh bảo mật
- Không bao giờ đẩy file này lên repository
- Nếu file bị lộ, hãy thông báo ngay cho quản trị viên dự án 