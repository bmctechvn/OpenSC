
## **Ghi nhớ: Cài đặt HSM với USB Token trên Yocto**

### **Mục tiêu:** Xây dựng một image Linux tùy chỉnh bằng Yocto để chạy ứng dụng HSM API Server, sử dụng các USB token (CCID/smartPGP) làm module mã hóa.

-----

### \#\# 1. Các Package cần thêm vào Yocto Image

Đây là các recipe bạn cần thêm vào file cấu hình image của mình (ví dụ: `conf/local.conf` hoặc file `.bb` của image).

```conf
# Trong file local.conf hoặc file image recipe của bạn

# Gói hệ thống cơ bản
# - opensc: Cung cấp driver và công cụ (pkcs11-tool) cho smart card.
# - pcsc-lite: Dịch vụ nền quản lý đầu đọc thẻ (pcscd).
# - p11-kit: Công cụ quản lý và tổng hợp các module PKCS#11.
# - libengine-pkcs11-openssl: (Tùy chọn) Cầu nối để OpenSSL có thể dùng PKCS#11.
IMAGE_INSTALL:append = " opensc pcsc-lite p11-kit libengine-pkcs11-openssl"

# Môi trường Python
# - python3-pip: Trình quản lý gói của Python.
# - python3-venv: (Khuyến nghị) Để tạo môi trường ảo cho ứng dụng.
IMAGE_INSTALL:append = " python3 python3-pip python3-venv"

# Các thư viện Python cho ứng dụng API
# Thêm các recipe này để chúng được cài đặt sẵn trong image.
# Tên recipe thường là python3-<tên-gói-pip>.
IMAGE_INSTALL:append = " python3-fastapi python3-uvicorn python3-gunicorn python3-pkcs11"
```

-----

### \#\# 2. Cấu hình hệ thống sau khi Flash Image

Sau khi đã có image và chạy trên kit i.MX 8, bạn cần thực hiện các bước cấu hình sau. Các bước này có thể được tự động hóa bằng script trong quá trình build Yocto.

#### **a. Đăng ký OpenSC với p11-kit**

Đây là bước quan trọng nhất để ứng dụng Python có thể thấy các token.

1.  **Tìm đường dẫn của driver OpenSC:**

    ```bash
    find /usr -name "opensc-pkcs11.so"
    ```

    *(Kết quả thường là `/usr/lib/opensc-pkcs11.so`)*

2.  **Tạo file cấu hình module:**
    Tạo file `/usr/share/p11-kit/modules/opensc.module` với nội dung sau (thay thế đúng đường dẫn):

    ```
    module: /usr/lib/opensc-pkcs11.so
    ```

#### **b. (Nếu cần) Vô hiệu hóa Module TPM**

Nếu bạn gặp lỗi liên quan đến TPM, hãy vô hiệu hóa module của nó để tránh xung đột.

1.  **Tìm file module TPM:**

    ```bash
    find /usr/share/p11-kit/modules/ -name "*tpm*"
    ```

2.  **Đổi tên để vô hiệu hóa:**

    ```bash
    sudo mv /path/to/tpm2-pkcs11.module /path/to/tpm2-pkcs11.module.disabled
    ```

-----

### \#\# 3. Triển khai ứng dụng Python

1.  **Tạo và kích hoạt môi trường ảo:**

    ```bash
    cd /path/to/your/app
    python3 -m venv venv
    source venv/bin/activate
    ```

2.  **Cài đặt thư viện (nếu chưa có trong image):**

    ```bash
    pip install fastapi uvicorn gunicorn python-pkcs11
    ```

3.  **Chạy ứng dụng bằng Gunicorn:**
    Sử dụng một lệnh đầy đủ với các cấu hình quan trọng.

    ```bash
    gunicorn main:app \
        --workers 4 \
        --worker-class uvicorn.workers.UvicornWorker \
        --bind 0.0.0.0:8000 \
        --timeout 120
    ```

-----

### \#\# 4. Các lệnh kiểm tra và gỡ lỗi hữu ích

  * **Kiểm tra phần cứng USB:**

    ```bash
    lsusb
    ```

  * **Kiểm tra dịch vụ PC/SC:**

    ```bash
    pcsc_scan
    ```

  * **Kiểm tra `p11-kit`:**

    ```bash
    p11-kit list-modules
    ```

  * **Kiểm tra trực tiếp với OpenSC:**

    ```bash
    pkcs11-tool --list-slots
    pkcs11-tool --login --pin <PIN> --list-objects --slot <ID>
    ```

  * **Chạy `pcscd` ở chế độ debug:**

    ```bash
    sudo systemctl stop pcscd
    sudo pcscd --foreground --debug
    ```
	
// More
// SSL
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365
