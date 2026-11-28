# Jawaban Analisis — Modul 08 (draf)

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 08** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m08/catatan-bukti.md`, `latihan-m08.md`, tautan run, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (C1–C6, O1, E4, E5) saat memakai faktanya, dan rujuk baris `K-08-*` bila relevan.

## Pertanyaan 1 — Cluster, container tanpa cluster, atau fungsi

| Aspek | ECS Fargate (modul ini) | Lambda (pengarsip) | Kubernetes terkelola (EKS) |
|---|---|---|---|
| Waktu siap dari nol (angka saya) | stack 33 resource dari nol sampai sehat ≤ 9 menit 12 detik; task tambahan sehat ±45 detik setelah desired naik (23:03:11 → 23:03:56) | init 248–315 ms, pesanan terarsip 1–2 detik setelah dikirim | — (tidak dibangun) |
| Biaya saat sepi | minimal 1 task dan ALB tetap ditagih per jam walau tanpa permintaan | nol bila tidak ada pesan, ditagih per pemanggilan | control plane ditagih per jam ditambah node (dikutip, tidak diukur) |
| Kendali dan beban operasional | tim memilih image, CPU/memori, jaringan, skala; tidak mengurus server | hampir tanpa kendali runtime, beban operasional paling kecil | kendali paling besar (penjadwalan, jaringan, add-on) tetapi upgrade dan operasi cluster ditanggung tim |

Komponen kasus saya yang sebaiknya di masing-masing platform (C1, C2, C6; Morris hlm. 231–236):

Yang saya ukur sendiri: Fargate butuh hitungan menit untuk menambah kapasitas dan tetap menyala saat sepi, sedangkan Lambda menyala dalam ratusan milidetik dan tidak memakan biaya saat tidak ada pesan. Yang saya kutip: EKS memberi kendali penuh atas cluster tetapi membawa beban operasi cluster sendiri (Domingus & Arundel, 2022, hlm. 37–45). Untuk KSL, API pendaftaran dan jadwal (C1) cocok di container yang selalu menyala seperti Fargate, karena dijaga SLO 99,95% dan p95 < 500 ms dan harus siap saat puncak pagi Senin 4,7× (C2). Worker notifikasi dan pengarsip cocok di fungsi karena dipicu event dan bebannya meledak sesaat, misalnya pengingat pukul 18.00 (C2). Portal jadwal publik boleh di serverless seperti Cloud Run, tetapi API rekam medis tidak boleh di serverless publik (C6), sehingga tetap di container dalam jaringan privat. EKS baru layak bila lima tim (C5) memang memerlukan satu cluster bersama dengan kebijakan seragam.

## Pertanyaan 2 — Skala dan batasnya

Data skala saya (Latihan 8.1 butir 1):

Beban `/hitung` mulai 22:57:59 membuat CPU 86–87%, tetapi desired baru naik ke 2 pada 23:03:09 (menit ke-5) dan running 2 pada 23:03:56. Target tracking menunggu alarm CloudWatch yang dihitung dari rata-rata per menit selama beberapa titik data, lalu task baru masih perlu menarik image dan lulus health check. Setelah beban berhenti, task tidak langsung turun karena alarm turun lebih konservatif dan ada cooldown masuk 120 detik (K-08-003).

Hitungan kapasitas untuk puncak C3 kasus saya dan batas C5:

Dari beban `/` saya, satu task 0,25 vCPU melayani ±1,1 rps dengan CPU ±24%, jadi pada target 50% kira-kira 2,3 rps per task. Untuk puncak 420 rps (C3) itu berarti ±180 task kecil. Angka ini terlalu pesimis karena bebannya tertahan jaringan laptop ke Sydney (p95 belasan detik padahal CPU rendah), sehingga kapasitas per task yang sebenarnya harus diukur dari dalam region. Tetap saja jumlahnya jauh di atas batas 3 task di lab, dan C5 menyebut kuota cluster dibagi lima tim; bila batas tercapai, permintaan menumpuk di task yang ada dan p95 melewati E5. Jadi `skala_maks` produksi harus dihitung dari rps per task hasil uji beban dan dinegosiasikan sebagai kuota tim.

Apa yang menjadi hambatan berikutnya setelah API diskalakan:

Setelah lapisan API yang stateless bisa diperbanyak, hambatan pindah ke komponen yang menyimpan state (Gorton, 2022, hlm. 102–107). Di KSL itu database RME, karena satu pembukaan rekam medis memicu 14 kueri (E3), sehingga 420 rps API bisa berarti ribuan kueri per detik; karena itu C3 juga merencanakan 70 server cache. Antrean juga perlu dicek: worker harus sanggup 30.000 pesan per jam (±8 pesan per detik) tanpa menumpuk di DLQ.

## Pertanyaan 3 — Canary dan keputusan promosi

Distribusi versi saya (Latihan 8.1 butir 2) dan aturan C4:

Dengan bobot 20 saya mengukur ±15% (26 dari ±170 jawaban), dan dengan bobot 5 sesuai C4 terukur 6,5% (33 dari 507), keduanya dalam 1,5 simpangan baku binomial. Di target group canary 8.2.0 tidak ada 5xx dan p95 2,5 ms, sehingga dipromosikan. Percobaan kelas juga menunjukkan risiko canary sendiri: menaikkan bobot sebelum canary sehat menghasilkan 5 gagal, dan menghapus canary sebelum bobotnya nol menghasilkan 33 gagal (K-08-001).

Kapan canary, blue-green (Modul 06), atau rolling update (Morris hlm. 381–382):

Canary paling tepat bila risikonya ada pada perilaku versi baru di depan pengguna nyata dan organisasi ingin membatasi siapa yang terdampak, persis seperti uji fitur di dua klinik percontohan dengan ±5% lalu lintas (C4). Blue-green lebih tepat bila perpindahannya harus utuh sekaligus dan rollback harus seketika, misalnya memindahkan legacy seperti di Modul 06, dengan biaya dua lingkungan penuh selama transisi. Rolling update bawaan ECS cukup untuk perubahan berisiko rendah seperti tambalan konfigurasi, karena tidak memberi kesempatan mengamati versi baru pada sebagian kecil lalu lintas sebelum semua task diganti.

Metrik dan ambang promosi atau rollback (O1, E5):

Aturan otomatis yang saya usulkan (K-08-002): canary 5% di luar puncak pagi, diamati minimal 10 menit dan minimal 200 permintaan ke canary. Promosi bila 5xx target group canary 0 dan p95 canary < 500 ms (E5) serta tidak lebih buruk dari stabil. Rollback otomatis, dengan bobot kembali ke 0, bila laju 5xx canary melewati 0,05% (O1) atau p95 melewati 500 ms selama dua menit berturut-turut. Ambang 200 permintaan dipakai karena dengan sampel kecil satu atau dua galat tidak bisa dibedakan dari kebetulan; pada uji saya canary baru menerima 36 permintaan, sehingga di produksi pengamatan perlu diperpanjang sampai syarat itu terpenuhi.

## Pertanyaan 4 — Bangun ulang dari nol

Angka bangun ulang saya (destroy, apply, sampai sehat):

Bongkar 33 resource 4 menit 12 detik (00:02:30–00:06:42), bangun ulang 33 resource sampai `SEHAT setelah 0.6 detik` paling lama 9 menit 12 detik, total 13 menit 24 detik dari awal bongkar sampai sehat. Ini membuktikan semester ini menghasilkan infrastruktur yang reproducible dan disposable (Morris, 2025, hlm. 22–24): semua yang berjalan berasal dari repo, sehingga membangun ulang sama dengan membangun lingkungan baru, dan setiap penerapan sekaligus latihan pemulihan bencana (hlm. 385).

Yang tidak ikut dibangun ulang dan akibatnya bagi pemulihan bencana (E4/O1; Morris hlm. 22–24, 383–385):

Registri dan image, bucket state, serta stack `m00-*` tidak ikut dibangun ulang, sedangkan isi arsip, pesan di DLQ, log pengarsip, dan nama DNS ALB hilang atau berubah (K-08-004). Untuk KSL, pemulihan ±9–13 menit sudah memakan 42–62% anggaran galat bulanan 21,6 menit (E4/O1) untuk satu kejadian, dan data yang hilang tidak bisa diterima karena arsip pasien wajib disimpan lama. Data harus berada di stack dengan siklus hidup berbeda dan dicadangkan, karena data yang dihasilkan sistem tidak bisa didefinisikan ulang dari kode (Morris, 2025, hlm. 23, 383–384). Agar penerapan layanan juga hanya lewat pipeline, workflow perlu menjalankan `tofu plan` di PR dan `tofu apply` stack `m08-layanan` di `main` setelah image terdorong. Role pipeline lalu butuh izin ECS (register task definition, create/update/delete service), `iam:PassRole` terbatas untuk role eksekusi dan role task, Elastic Load Balancing, security group EC2, Application Auto Scaling, SNS, SQS, Lambda, S3, dan CloudWatch Logs, semuanya dibatasi pada nama `koma-123450039-m08-*`, ditambah akses ke bucket state.
