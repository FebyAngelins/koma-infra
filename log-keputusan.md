# Log Keputusan

Satu baris per keputusan desain. ID berbentuk `K-<modul>-<nomor>`, misalnya `K-01-001`. Alasan
merujuk kode bukti kasus kelompok (P1–P6, E1–E8, …). Keputusan kelompok yang sama boleh muncul di
repo setiap anggota; kolom Pengusul diisi NIM anggota yang mengusulkan.

| ID | Tanggal | Keputusan | Alasan (rujuk kode bukti kasus) | Pengusul (NIM) |
|---|---|---|---|---|
| K-01-001 | 2026-11-06 | Katalog `layanan` sandbox berisi tiga entri: `portal` (peran web), `rme-api` (peran api), dan `notif-worker` (peran worker). | E1 dan Pemetaan ke aplikasi contoh: portal pasien dan dasbor klinik, API pendaftaran dan RME, serta worker pengirim hasil lab dan notifikasi adalah tiga komponen aplikasi KSL; kunci memakai nama komponen agar tag `Name` dan `peran` dapat dibaca auditor (P5, Babak 1). | 123450039 |
| K-01-002 | 2026-11-06 | Preset ukuran: `rme-api` = `sedang` (t3.small); `portal` dan `notif-worker` = `kecil` (t3.micro). | E4: API RME dan pendaftaran wajib SLA 99,95%, portal cukup 99,5%; E5: p95 API RME < 500 ms; E3: satu pembukaan rekam medis memicu 14 kueri. Worker bekerja di latar dan tidak sensitif latensi. | 123450039 |
| K-01-003 | 2026-11-06 | Instance dibuat dengan `for_each` atas map `layanan` (bukan `count`), dan refaktor `aws_instance.web` memakai blok `moved`. | E4 SLA 99,95% (anggaran galat ±21,6 menit per bulan): server yang melayani RME tidak boleh dibuat ulang hanya karena kode dirapikan. `count` menggeser indeks saat entri dihapus sehingga server lain ikut diganti; `moved` menjaga ID instance tetap (terbukti `refaktor_tanpa_ganti`). | 123450039 |
| K-01-004 | 2026-11-06 | Semua instance tanpa IP publik (`associate_public_ip_address = false`) dan atribut subnet bawaan `MapPublicIpOnLaunch` dimatikan. | P4/E8: API dan database RME tetap privat dan identitas pasien tidak boleh terbuka ke internet; di sandbox, subnet bawaan memberi IP publik walau kode menyatakan `false`, sehingga pengaturan subnet ikut dicatat agar tidak menjadi keputusan tersembunyi (P5). | 123450039 |
