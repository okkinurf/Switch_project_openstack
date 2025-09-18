# 🔄 OpenStack Switch Project Script

Script Bash untuk **menukar (switch) project role** antara 2 user di OpenStack.  
Mendukung interaktif, konfirmasi, `--dry-run`, dan spinner progress.

---

## 📥 Instalasi
Clone repo atau salin script:

```bash
git clone https://github.com/username/openstack-switch-project.git
cd openstack-switch-project
chmod +x switch-project.sh
```

## ⚙️ Prasyarat

Linux / WSL / macOS dengan Bash

Sudah terinstal OpenStack CLI

Sudah login ke OpenStack (openrc / environment vars)

▶️ Cara Menjalankan
Mode Interaktif
```
./switch-project.sh
```

Script akan menanyakan:

Email Pengguna 1

Email Pengguna 2

Konfirmasi sebelum eksekusi

Mode dengan argumen
```
./switch-project.sh -u1 user1@neo.id -u2 user2@neo.id
```

Mode otomatis (skip konfirmasi)
```
./switch-project.sh -u1 user1@neo.id -u2 user2@neo.id --yes
```

Mode simulasi (tanpa eksekusi perubahan)
```
./switch-project.sh -u1 user1@neo.id -u2 user2@neo.id --dry-run
```
## 📋 Contoh Output
```
=== 🔄 NEO - Switch Project ===

🔎 Mengambil informasi project awal...

--- REVIEW SEBELUM PERUBAHAN ---
========================
🔹 user1@neo.id
   ID User   : 123abc456
   Project ID: proj-1111

🔹 user2@neo.id
   ID User   : 789def012
   Project ID: proj-2222
========================

Apakah Anda yakin ingin melanjutkan? (y/n): y

🚀 Memulai proses penukaran...
🔄 Menambahkan role user2@neo.id ke proj-1111 |✅
🔄 Menambahkan role user1@neo.id ke proj-2222 |✅
🔄 Menghapus role user1@neo.id dari proj-1111 |✅
🔄 Menghapus role user2@neo.id dari proj-2222 |✅
✅ Proses penukaran selesai.

📋 Before
========================
🔹 user1@neo.id
   ID User   : 123abc456
   Project ID: proj-1111

🔹 user2@neo.id
   ID User   : 789def012
   Project ID: proj-2222
========================

✅ After
========================
🔹 user1@neo.id
   ID User   : 123abc456
   Project ID: proj-2222

🔹 user2@neo.id
   ID User   : 789def012
   Project ID: proj-1111
========================
```

## 🛠️ Fitur

🔎 Validasi email user & project

🔄 Tukar role antar 2 user

✅ Konfirmasi interaktif (atau skip dengan --yes)

🌀 Spinner + titik progress

🧪 Mode simulasi --dry-run

📋 Ringkasan Before & After
