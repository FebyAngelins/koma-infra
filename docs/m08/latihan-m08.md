# Latihan 8.1 — Skala, canary, dan satu pesanan yang terbukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m08.json` (setelah Bagian F, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 08**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier atau 12 digit ID akun (tulis `<akun>`); nama DNS ALB boleh ditulis.

## 1. Skala yang terbukti (C.2)

Ringkasan `koma beban`:

```text
Sun Nov 22 22:57:59 WIB 2026
Beban GET http://koma-123450039-m08-428846181.ap-southeast-2.elb.amazonaws.com/hitung?n=3000000 dengan 4 pekerja selama 300 dtk ...
Permintaan 191, gagal 5, p50 3703 ms, p95 18424 ms
Ringkasan: .koma/beban-m08.json
Sun Nov 22 23:03:03 WIB 2026
```

| Menit sejak beban mulai | `desiredCount` stabil | `runningCount` stabil | Catatan (aktivitas skala) |
|---|---|---|---|
| 0 (22:57:59) | 1 | 1 | Beban mulai. CPU rata-rata menit 22:58 = 86,4%, 22:59 = 87,2% |
| 3,8 (23:01:47) | 1 | 1 | CPU masih di atas target 50% (23:00 = 50,6%, 23:01 = 76,1%); belum ada aktivitas skala |
| 5,2 (23:03:09) | 2 | 1 | Aktivitas skala: "Setting desired count to 2." |
| 6,0 (23:03:56) | 2 | 2 | Task kedua sudah RUNNING dan terdaftar di target group |
| 7,3 (23:05:17) | 2 | 2 | Beban sudah berhenti (23:03:03), task belum diturunkan karena cooldown masuk 120 dtk dan alarm turun butuh beberapa menit data rendah |

Mengapa jumlah task tidak naik seketika, dan mengapa tidak langsung turun setelah beban berhenti:

Target tracking tidak membaca CPU detik per detik. Ia menunggu metrik CloudWatch rata-rata per menit dan alarm "tinggi" harus terpenuhi selama beberapa titik data berturut-turut, baru kebijakan menaikkan desiredCount. Pada percobaan saya CPU sudah di atas 80% sejak menit pertama, tetapi desiredCount baru berubah di menit ke-5. Setelah itu task baru juga butuh waktu sekitar 45 detik untuk menarik image, menyala, dan lulus health check sebelum runningCount ikut naik. Saat beban berhenti, penurunan sengaja dibuat lebih lambat: alarm "rendah" butuh lebih banyak titik data dan ada cooldown scale-in 120 detik, supaya layanan tidak naik turun bolak-balik ketika beban hanya jeda sebentar.

Perbandingan dengan kebutuhan skala C3 dan batas C5 kasus saya:

C3 Klinik Sehat Lampung memperkirakan API naik dari 90 ke 420 rps, dengan rencana 24 server API. Batas tiga task di lab jauh di bawah itu, jadi angka 3 hanya cocok untuk percobaan, bukan untuk puncak pagi Senin atau musim MCU. Namun C5 menyebut cluster dipakai lima tim dengan kuota yang sama, sehingga batas atas tetap wajib ada agar satu layanan tidak menghabiskan kuota tim lain. Di produksi `skala_maks` perlu dihitung dari rps per task hasil uji beban dan dibagi adil dengan kuota tim lain, bukan dibuat tanpa batas.

## 2. Canary yang terukur (D.2)

Ringkasan `koma probe` dengan bobot canary 20:

```text
Sampel 276, gagal 5, jeda terpanjang 3.1 dtk, versi {'8.0.0': 245, '8.1.0': 26}, alih pada detik 106.0
```

| Sampel | Jawaban versi stabil | Jawaban versi canary | Persen canary |
|---|---|---|---|
| 276 total (271 berhasil); sekitar 170 sesudah 8.1.0 pertama menjawab di detik 106 | sekitar 144 (8.0.0) | 26 (8.1.0) | 26/170 ≈ 15,3% |

Mengapa persentase yang terukur tidak tepat 20, dan berapa sampel yang dibutuhkan agar selisihnya kecil:

Bobot 20 di listener adalah peluang tiap permintaan diteruskan ke canary, bukan pembagian yang pasti. Jumlah jawaban canary mengikuti sebaran binomial. Dengan n = 170 dan p = 0,2, simpangan bakunya akar(0,2 × 0,8 / 170) ≈ 3,1 poin persen. Hasil 15,3% berjarak sekitar 1,5 simpangan baku dari 20%, jadi masih wajar. Lima kegagalan di awal (detik 76–92) muncul karena bobot sudah 20 sebelum task canary sehat, dan itu ikut mengurangi jawaban canary. Agar selisihnya sekitar ±2 poin persen dibutuhkan kira-kira 400 sampel, dan untuk ±1 poin persen sekitar 1.600 sampel.

Metrik yang akan saya pakai untuk memutuskan promosi atau rollback (kaitkan dengan O1/E5 kasus saya):

O1 menargetkan ketersediaan 99,95% dengan galat paling banyak 0,05%, dan E5 meminta p95 di bawah 500 ms. Untuk canary saya akan memakai bobot 5% (sesuai C4: dua klinik percontohan, di luar puncak pagi), diamati minimal 10 menit dan minimal 200 permintaan ke canary. Canary dipromosikan hanya bila jumlah 5xx pada target group canary 0 dan p95 canary di bawah 500 ms serta tidak lebih buruk dari stabil. Bila ada satu saja 5xx atau p95 melewati 500 ms, bobot dikembalikan ke 0 lalu canary dihapus.

## 3. Satu pesanan dari API ke arsip (B.6)

Keluaran `koma pesan` (satu baris):

```text
  202  P-c80b0de3ac87  8.0.0
```

Kunci objek di bucket arsip dan baris log fungsi pengarsip untuk pesanan itu:

```text
s3://koma-123450039-m08-prod-arsip-530545857345/arsip/2026-11-22/P-c80b0de3ac87.json   (2026-11-22 22:48:15 WIB, 155 byte)

/aws/lambda/koma-123450039-m08-prod-pengarsip
2026-11-22T15:48:14.105000+00:00 2026/11/22/[$LATEST]ff936cf8dffb4e3a993e823af027d5d5 {"arsip": "arsip/2026-11-22/P-c80b0de3ac87.json"}
2026-11-22T15:48:14.108000+00:00 2026/11/22/[$LATEST]ff936cf8dffb4e3a993e823af027d5d5 REPORT RequestId: 29c1266b-3b5b-5cb4-9619-45162bacfa58	Duration: 1329.80 ms	Billed Duration: 1578 ms	Memory Size: 256 MB	Max Memory Used: 92 MB	Init Duration: 247.47 ms
```

Jalur pesanan dan identitas yang mengizinkan setiap langkahnya:

Klien mengirim POST ke ALB, lalu ALB meneruskannya ke task ECS versi stabil. Task menerbitkan pesanan ke topik SNS `koma-123450039-m08-prod-pesanan` dengan role task `koma-123450039-m08-api`, yang hanya diberi `sns:Publish` ke ARN topik itu lewat kebijakan `terbitkan-pesanan`. SNS meneruskan pesan ke antrean SQS karena kebijakan antrean mengizinkan prinsipal `sns.amazonaws.com` mengirim pesan dengan syarat `aws:SourceArn` sama dengan topik tersebut. Fungsi Lambda pengarsip kemudian dipicu oleh event source mapping. Role fungsinya diizinkan membaca dan menghapus pesan dari antrean, lalu menulis `arsip/2026-11-22/P-c80b0de3ac87.json` ke bucket arsip dengan `s3:PutObject`. Seluruh jalur selesai kurang dari dua detik. Bila pesan gagal diproses berulang kali, ia dipindahkan ke DLQ dan tidak hilang.

## 4. Bukti

- Potret 2 (C.2) pada 22 November 2026 sekitar 23:05 WIB, `skala_keluar`: `koma cek m08` ditolak verifier (403 Forbidden), sehingga potret tidak terbentuk. Sesuai arahan dosen, bukti skala diambil dari `.koma/beban-m08.json` dan keluaran `describe-services`/`describe-scaling-activities` di atas.
- Potret 3 (D.2) pada 22 November 2026 sekitar 23:33 WIB, `canary_berbobot`: sama, verifier 403. Bukti canary diambil dari ringkasan probe di atas.
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m08.json` yang diunggah: belum tersedia karena verifier menolak (403) sepanjang modul.
