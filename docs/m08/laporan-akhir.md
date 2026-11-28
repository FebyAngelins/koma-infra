# Laporan Akhir Kelompok — Platform Cloud Klinik Sehat Lampung

| Hal | Isi |
|---|---|
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Anggota (NIM — nama — repo `koma-infra`) | 123450039 — Feby Angelina — `FebyAngelins/koma-infra` |
| Tanggal | 28-11-2026 |

Laporan ini ditulis **bersama** oleh kelompok dan disalin sama ke `docs/m08/laporan-akhir.md` di repo setiap anggota (tenggat Jumat 28-11). Rujuk tag, berkas, nomor run, dan baris `K-NN-*` alih-alih menyalin isinya. Panjang yang disarankan 1.500–2.500 kata. Setiap angka menyebut sumbernya (catatan bukti anggota mana, modul mana).

Kelompok k01 beranggotakan satu orang (baris peninjau di `TIM.md` berisi `-` untuk semua modul), sehingga semua angka di laporan ini berasal dari repo `FebyAngelins/koma-infra`, tag `m01`–`m08`.

## 1. Ringkasan untuk direksi

KSL memulai semester dengan insiden P5: Senin pukul 07.40, saat puncak pendaftaran, RME berhenti 190 menit karena volume log transaksi penuh, tanpa alert, dan Divisi TI baru tahu setelah 23 klinik menelepon (O5: 25 menit). Akar masalahnya adalah server yang dibuat dan diubah dengan tangan, tanpa catatan dan tanpa pemantauan. Sekarang seluruh infrastruktur percontohan didefinisikan sebagai kode di satu repo, berubah hanya lewat pull request dan pipeline OIDC, dipantau alarm p95, dan dapat dibangun ulang dari nol: layanan API cloud-native (33 resource) dibongkar dalam 4 menit 12 detik dan dibangun kembali sampai sehat dalam paling lama 9 menit 12 detik (catatan M08 Bagian E). Risiko terbuka terbesar adalah data: arsip pesanan dan log ikut terhapus saat layanan dibangun ulang, dan bila tidak dipisah serta dicadangkan, pemulihan cepat tetap berarti kehilangan data pasien (K-08-004, S5).

## 2. Arsitektur akhir

```text
                 Pasien / klinik / kios (IP diizinkan)
                               │ HTTP 80
                     ┌─────────▼─────────┐
                     │  ALB  (listener   │  bobot stabil/canary  ← kode: m08-layanan
                     │  forward 95/5)    │
                     └───┬───────────┬───┘
                 TG stabil│           │TG canary
            ┌─────────────▼──┐   ┌────▼───────────┐
            │ ECS Fargate    │   │ ECS Fargate    │  task 0,25 vCPU, root fs baca-saja,
            │ API 8.2.0      │   │ API canary     │  role task hanya sns:Publish
            │ autoscale 1–3  │   └────────────────┘  target tracking CPU 50%
            └───────┬────────┘
                    │ sns:Publish
             ┌──────▼──────┐   ┌───────────┐   ┌──────────────┐   ┌───────────────┐
             │ SNS pesanan ├──►│ SQS antre ├──►│ Lambda       ├──►│ S3 arsip      │
             └─────────────┘   └─────┬─────┘   │ pengarsip    │   │ (force_destroy│
                                     │ 3×gagal └──────────────┘   │  di lab)      │
                                ┌────▼────┐                       └───────────────┘
                                │  DLQ    │           ← kode: modul antrean-arsip (M07)
                                └─────────┘

Di luar stack layanan (tidak ikut dibangun ulang):
  ECR koma-123450039-m08-api (tag IMMUTABLE)          ← kode: m08-registri
  Bucket state S3 berversi + kunci (M04)              ← kode: m00-state
  Role pipeline OIDC, role verifier, budget, pagar S3 ← kode: m00-*
  Akun AWS, IP praktikan, kasus KSL                    ← di luar kode

Tetap on-premises menurut keputusan kasus:
  Database RME 6,8 TB dan hasil lab (H1, K-06-001)     ← tidak dimigrasi
```

## 3. Perjalanan per babak

| Babak | Pertanyaan untuk kasus kelompok | Keputusan utama (`K-NN-*`) | Bukti (tag, berkas, run) |
|---|---|---|---|
| M01 | Insiden apa yang memicu perubahan (P5)? | K-01-001 katalog tiga komponen; K-01-003 `for_each` + `moved` agar refaktor tidak mengganti server SLA 99,95% | tag `m01`, `docs/m01/catatan-bukti.md`, uji `refaktor_tanpa_ganti` |
| M02 | Bake atau fry? | K-02-003 API dipanggang ke AMI; K-02-001 rilis immutable 2.2.0 | tag `m02`, jeda rilis terukur ±6 menit (K-02-001) |
| M03 | Jalur mana yang ditutup (E3, A3)? | K-03-003 vendor kios dan lab hanya lewat ALB, tanpa SSH; K-03-002 dua server di dua AZ | tag `m03`, `docs/m03/catatan-bukti.md` |
| M04 | Data mana yang harus selamat (S1–S4)? | K-04-002 versi objek 90 hari untuk unggahan; K-04-003 rahasia tidak pernah di kode, state dibatasi | tag `m04`, `stacks/m04-data` |
| M05 | Temuan paling berbahaya (A6) dan pagarnya? | K-05-001 bucket laporan publik ditutup dengan blok publik akun + SSE-KMS; K-05-003 password di Parameter Store dengan rotasi | tag `m05`, `docs/m05/laporan-audit.md` |
| M06 | Bagaimana legacy dipindah dalam batas L4; SLO apa yang dijaga (O1)? | K-06-001 matriks rehost → replatform; K-06-003 alarm p95 0,3 detik; K-06-004 contract setelah alih dan rollback terlatih | tag `m06`, probe contract 239 sampel 0 gagal |
| M07 | Siapa membayar apa (G1, G3); apa yang hanya lewat pipeline (H6)? | K-07-001 `cost-center` per lingkungan; K-07-003 DLQ di prod; K-07-004 trust OIDC subjek imutabel | tag `m07`, run 45024392050 (gagal trust), 45028860839 (bongkar lewat pipeline) |
| M08 | Cluster atau serverless (C6); berapa menit bangun ulang? | K-08-001 canary dua langkah; K-08-002 bobot 5% dan kriteria promosi; K-08-003 skala CPU 50%; K-08-004 registri terpisah | tag `m08`, run image 45036091216, 45043331445, 45048570130 |

M01 adalah titik balik cara berpikir. Insiden P5 terjadi karena server dirawat dengan tangan, dan audit menemukan server uji laboratorium yang tidak jelas pemiliknya. Dengan konvensi nama, label wajib, dan `for_each`, setiap resource punya pemilik dan alasan di `log-keputusan.md`. Blok `moved` membuktikan kode bisa dirapikan tanpa mengganti server yang melayani SLA 99,95% (E4), yang menjadi dasar semua refaktor berikutnya.

M04 dan M05 menjawab sisi data dan keamanan yang paling dekat dengan P5 dan A6. Ukuran RME (S1: 6,8 TB, tumbuh 1,9 TB per tahun) dan pengalaman restore foto yang gagal (S6) menunjukkan bahwa yang paling sulit dipulihkan adalah data, bukan server. Karena itu state dipisah ke bucket berversi, unggahan diberi retensi versi 90 hari, dan rahasia tidak pernah masuk kode. Di M05 temuan paling berbahaya bagi KSL adalah bucket laporan yang terbuka publik, karena A6 sudah pernah terjadi: tautan hasil lab tersebar 11 hari.

M06 memindahkan Sistem Antrean Pendaftaran tanpa mengganggu 140 kios yang alamatnya tertanam di firmware (L2). Server hijau dibuktikan sehat lewat header uji sebelum listener dialihkan, alarm p95 0,3 detik dipasang lebih ketat dari E5, dan legacy baru dibongkar setelah rollback terlatih. Probe saat contract 239 sampel tanpa gagal.

M08 menyatukan semuanya. API stateless berjalan di ECS Fargate dengan image yang dibangun sekali oleh pipeline (tag tidak bisa ditimpa), autoscaling menaikkan task dari 1 ke 2 pada menit ke-5 beban CPU 86–87% (23:03:09 WIB, 22-11), canary 8.2.0 dengan bobot 5% sesuai C4 terukur 6,5% (33 dari 507 jawaban) tanpa 5xx dan p95 2,5 ms, dan seluruh layanan dibangun ulang dari repo dalam hitungan menit. Pelajaran terpenting justru dari kegagalan: promosi 8.1.0 satu langkah menghasilkan 33 permintaan gagal karena canary dihapus saat listener masih menunjuknya, dan perbaikannya (dua langkah plus `create_before_destroy`) sekarang menjadi aturan tertulis (K-08-001).

## 4. Keputusan arsitektur tersulit

**Konteks.** API pendaftaran KSL dijaga SLA 99,95% (E4), atau ±21,6 menit gangguan per bulan, dan p95 < 500 ms (E5). Fitur baru harus diuji di 2 klinik percontohan dengan ±5% lalu lintas di luar puncak pagi (C4). ALB mendukung forward berbobot ke dua target group, tetapi urutan perubahan listener, service, dan target group dalam satu `tofu apply` tidak bisa dikendalikan sepenuhnya.

**Pilihan.** Rilis canary dijalankan dua langkah (K-08-001, K-08-002). Pertama, service canary dibuat dengan bobot 0 dan ditunggu sampai sehat, baru bobot dinaikkan ke 5. Kedua, saat promosi bobot dikembalikan ke 0 dan di-apply, baru versi stabil diganti dan canary dihapus. Target group memakai `create_before_destroy`. Promosi hanya bila selama minimal 10 menit dan 200 permintaan ke canary tidak ada 5xx dan p95 < 500 ms.

**Alternatif yang ditolak.** Apply satu langkah lebih singkat, tetapi terbukti menimbulkan 5 gagal saat canary dinaikkan dan 33 gagal saat promosi (catatan M08 Bagian D). Blue-green seperti M06 memberi peralihan utuh dan rollback seketika, tetapi tidak memenuhi C4 yang meminta pengujian di sebagian kecil klinik, dan butuh kapasitas ganda. Rolling update bawaan ECS tidak memberi jendela pengamatan sebelum semua task diganti.

**Akibat.** Setiap rilis butuh tiga sampai empat apply dan lebih lama ±15 menit, tetapi canary 8.2.0 dirilis tanpa satu pun 5xx. Sisa risiko: di lab canary hanya menerima 36 permintaan, di bawah syarat 200, sehingga di produksi pengamatan harus lebih lama atau diotomatisasi dengan metrik CloudWatch.

## 5. Biaya dan pembersihan

| Hal | Isi |
|---|---|
| Tagihan akun 123450039 di akhir praktikum (Billing → Bills) | `<isi setelah pembersihan akhir kursus>` |
| Resource tersisa setelah Tugas M08 | stack `m00-*` (budget, bucket state, role verifier, pagar S3, provider OIDC, role pipeline); `m08-registri` dibongkar setelah Tugas diunggah |
| Bukti bersih | `koma sisa` setelah bongkar: hanya registri dan bucket state fondasi; cluster `INACTIVE` (catatan M08 Bagian F) |

Bila layanan M08 dibiarkan berjalan sebulan penuh pada skala lab (1 task Fargate 0,25 vCPU / 0,5 GB, satu ALB, SNS/SQS/Lambda/S3 dengan beban kecil), biayanya sekitar USD 30–40 per bulan. Komponen terbesar adalah ALB (biaya per jam ditambah LCU) dan task Fargate yang selalu menyala; Lambda, SQS, SNS, dan S3 hampir nol pada beban lab. Angka ini perkiraan dari harga publik region ap-southeast-2, bukan tagihan, dan perlu dicek ulang di AWS Pricing Calculator. Label `cost-center` (K-07-001) memungkinkan biaya ini ditelusuri ke CC-120 (Laboratorium) lewat `koma showback`.

## 6. Batas desain dan pekerjaan berikutnya

Pertama, data ikut hilang saat bangun ulang. Bucket arsip dan log pengarsip berada di stack layanan dengan `force_destroy`, sehingga pesanan `P-424b4a1b5c74` dan lainnya hilang saat layanan dibangun ulang. Perbaikannya: pindahkan bucket arsip ke stack data terpisah dengan `prevent_destroy`, versi objek, dan replikasi lintas region, sesuai retensi H4.

Kedua, penerapan layanan belum hanya lewat pipeline. Image sudah dibangun pipeline dengan OIDC, tetapi `tofu apply` stack layanan masih dijalankan dari laptop. Perbaikannya: workflow menjalankan plan di PR dan apply di `main`, dengan role pipeline yang diberi izin ECS, ELB, `iam:PassRole` terbatas, dan Auto Scaling, dibatasi pada nama `koma-123450039-m08-*`. Di samping itu, role untuk run `pull_request` dibuat baca-saja (K-07-004).

Ketiga, dev dan prod satu akun, dan image tanpa tanda tangan. Semua lingkungan berada di akun yang sama sehingga kesalahan di dev bisa menyentuh prod, dan image hanya dipindai, tidak ditandatangani. Perbaikannya: akun terpisah per lingkungan dengan AWS Organizations, serta penandatanganan image dan verifikasi saat deploy.

Keempat, kapasitas belum diuji dari dalam region. Pengukuran beban dari laptop ke Sydney tertahan jaringan (p95 belasan detik walau CPU rendah), sehingga rps per task untuk puncak 420 rps (C3) belum diketahui pasti, dan batas 3 task jauh di bawah kebutuhan. Perbaikannya: uji beban dari dalam VPC, lalu `skala_maks` dihitung dari hasilnya dan disepakati sebagai kuota tim (C5).

Kelima, verifier dosen menolak (403) sepanjang M08, sehingga potret otomatis tidak terbentuk dan bukti modul ini bergantung pada keluaran terminal, run Actions, dan CloudWatch yang dicatat manual.
