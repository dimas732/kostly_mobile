# Verifikasi properti KostLy

Pengiriman properti dijalankan oleh listener Firestore di `service_chatbot/bot.js`. Dari direktori backend tersebut, hentikan proses polling lama, pasok `BOT_TOKEN` dan `ADMIN_CHAT_ID` (ID grup negatif), lalu jalankan `npm start`. Gunakan service account untuk proyek Firebase yang sama dengan aplikasi. Satu proses polling menangani callback akun dan properti.

Form baru dan pengajuan ulang menulis `verification_status: pending` dan `telegram_delivery_status: queued` dalam satu operasi. Untuk pengajuan pending lama, tombol di profil memasukkan dokumen yang sama ke antrean. Backend mengambil klaim transaksional, mengirim satu pesan dengan tombol dan foto pertama yang didukung jika tersedia, lalu mencatat `telegram_sent_for` setelah Telegram memberikan ID pesan. Callback menggunakan versi waktu pengajuan, ID chat dan pemeriksaan status admin grup melalui getChatMember. Jadikan bot admin grup agar pemeriksaan anggota lain dapat diandalkan.

Jika Telegram menolak pengiriman, status menjadi `failed` dan pemilik bisa mencoba kembali. Jika respons hilang atau proses berhenti saat mengirim, status dapat menjadi `uncertain` atau tetap `sending`. Operator memeriksa ID kos di chat dan log bot sebelum mengambil tindakan. Jika pesannya ada, gunakan tombol pesan tersebut. Jika dipastikan belum terkirim dan pengirim lama sudah berhenti, operator dapat mengubah status pengiriman menjadi `failed` agar pemilik dapat mencoba lagi.

Gabungkan izin collection kos dari `firestore.proposed.rules` dengan rules aktif. Pemilik hanya boleh meminta antrean pada dokumennya sendiri. Lindungi role pada users dan field keputusan dari tulisan klien. Uji di staging sebelum merilis. Flutter lama perlu diperbarui. Endpoint `/notify` sudah dipensiunkan (410). Layanan HTTP di direktori ini hanya diperlukan untuk katalog legacy dan untuk menyelesaikan callback webhook lama jika sudah digunakan. Pertahankan konfigurasi HTTPS dan Firebase Auth katalog melalui `PROPERTY_API_URL`. Hindari memasang webhook pada token bot polling.

Notifikasi akun versi Flutter ini masih menggunakan pengirim akun lama. Pasok `OWNER_TELEGRAM_BOT_TOKEN` melalui konfigurasi build privat dengan `--dart-define-from-file`. Token tersebut tetap dapat diekstrak dari binary akun. Alur properti hanya memakai token backend.

Edit biasa hanya menulis informasi properti. Ini termasuk perubahan nama atau alamat kos terverifikasi. Jika perlu persetujuan ulang untuk perubahan tersebut, tetapkan daftar field yang signifikan dan kebijakan publikasi selama peninjauan, lalu tambahkan transisi backend dan aturan khusus. Pengajuan ulang saat ini adalah tindakan eksplisit pada kos ditolak. Transaksi menyimpan perbaikan sekaligus mereset keputusan pada dokumen yang sama.

## Data lama dan status akun

Firestore tidak menyediakan query untuk field yang tidak ada. Endpoint legacy memindai proyeksi ID dan status dengan paginasi, lalu hanya mengembalikan ID dokumen tanpa field tersebut. Home menggabungkan listener per ID yang diotorisasi rules dengan query verified. Wishlist menggunakan ID favorit dan query verified untuk mendeteksi persetujuan. Detail memeriksa ulang dokumen secara real-time. Pemilik menggunakan satu query UID untuk statistik dan kartu verifikasi.

Biaya pembacaan katalog lama meningkat seiring jumlah dokumen. Inventarisasi ID dan jumlahnya dahulu, cocokkan bukti keputusan dengan admin, lalu ajukan rencana backfill beserta cadangan, dry run, dan persetujuan pemilik proyek. Dokumen tanpa bukti tetap berstatus belum tercatat sampai melalui verifikasi. Setelah seluruh dokumen legacy terselesaikan, hapus endpoint dan listener legacy lalu batasi akses publik ke query verified.

Registrasi awal menulis `users.verification_status` dengan nilai awal `none`. Pengajuan dokumen akun menulis `users.verificationStatus` menjadi `pending`. Penulis keputusan akun berada di service_chatbot/bot.js. Pembacaan memakai status yang terisi jika pasangannya kosong atau `none`. Dua status substantif yang berbeda ditampilkan sebagai konflik. Untuk rekonsiliasi, periksa handler akun produksi dan keputusan pada `owner_applications/{uid}` sebelum memilih field otoritatif. Pembacaan profil tidak menulis ke akun.

## Pengujian staging

Jalankan `npm test` untuk keputusan callback. Dengan Firebase CLI dan Java, jalankan `firebase emulators:exec --config firebase.emulator.json --project demo-kostly --only auth,firestore "node --test rules.test.js backend.test.js"` untuk pengujian akses dan integrasi backend lokal dengan respons Telegram simulasi. Dari root aplikasi jalankan `flutter test` dan `flutter analyze`.

Di staging, gunakan akun pencari, dua pemilik, admin Telegram yang terdaftar dan pengguna Telegram lain. Ajukan dua kos, cocokkan ID di profil dan pesan. Setujui yang pertama lalu periksa Home, pencarian, wishlist dan detail. Tolak yang kedua, perbaiki dan ajukan ulang. Coba tombol lama, tombol ganda dan admin yang tidak terdaftar. Putuskan koneksi ke Telegram, simpan kos, lalu pulihkan dan ulangi pengiriman dari profil. Periksa jumlah dokumen, kedua tanggal, alasan, akses lintas pemilik, dan bahwa dokumen akun tidak berubah setelah keputusan properti. Ulangi pengajuan dan approval akun dengan bot lama. Verifikasi juga satu dokumen lama yang tidak memiliki field verifikasi.
