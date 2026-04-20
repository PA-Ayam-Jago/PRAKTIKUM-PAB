# Proyek Akhir PAB 2026
**Kelompok AYAM JAGO**

## Anggota Kelompok
- IRVANI CANLUSTY MISSA (2409116019)
- DENY CANDRA KASUMA (2409116024)
- ZELSYA RIZQITA RAHMADHINI (2409116022)
- NURHIDAYAH (2409116002)

## Mitra
Fakultas Ekonomi & Bisnis

## Deskripsi Aplikasi

Aplikasi ini merupakan pengembangan sistem **Reservasi dan Monitoring Studio Podcast FEB** yang sebelumnya masih dilakukan secara manual melalui WhatsApp tanpa pencatatan terpusat.

Pada proyek ini, aplikasi dikembangkan menggunakan **Flutter** dengan integrasi **Supabase** sebagai backend untuk autentikasi dan database.

Aplikasi ini memungkinkan pengguna untuk:
- Login dan register akun
- Melakukan reservasi studio
- Melihat dan mengelola reservasi
- Monitoring penggunaan studio
- Melihat riwayat peminjaman

## Permasalahan

- Proses peminjaman masih manual (WhatsApp)
- Tidak ada database terpusat
- Tidak ada sistem monitoring
- Riwayat tidak tercatat
- Bergantung pada satu admin

## Solusi

Mengembangkan aplikasi mobile berbasis Flutter dengan Supabase untuk:
- Digitalisasi reservasi studio
- Penyimpanan data terpusat
- Sistem approval reservasi
- Monitoring penggunaan
- Riwayat peminjaman yang terstruktur

## Fitur Aplikasi

### 1. Login Page

Pengguna dapat login menggunakan email dan password yang terdaftar pada Supabase.

### 2. Register Page
https://github.com/PA-Ayam-Jago/PRAKTIKUM-PAB/blob/3b89ffd51ede7aefe3d6e819632c6d6ac5265f0a/IMG-20260420-WA0015.jpg

Pengguna dapat membuat akun baru dengan role (Mahasiswa/Admin).

### 3. Home Page
Menampilkan daftar reservasi studio yang tersedia serta navigasi ke fitur lainnya.

### 4. Reservasi Page
Digunakan untuk:
- Menambah reservasi
- Melihat reservasi
- Edit reservasi
- Membatalkan reservasi

### 5. Admin Page
Admin dapat:
- Menyetujui (approve) reservasi
- Menolak reservasi

### 6. Profile Page
Menampilkan data pengguna.

### 7. Riwayat Reservasi
Menampilkan histori penggunaan studio.

## Fitur CRUD

### Create
Menambahkan data reservasi ke database Supabase.

### Read
Menampilkan daftar reservasi dari database.

### Update
Mengubah data reservasi.

### Delete
Menghapus atau membatalkan reservasi.

## Integrasi Supabase

Digunakan untuk:
- Authentication (Login & Register)
- Database (CRUD reservasi)

Contoh tabel:
### reservasi
- id
- user_id
- tanggal
- waktu
- status
- keterangan

## Widget yang Digunakan

### MaterialApp

```
MaterialApp(
  debugShowCheckedModeBanner: false,
  home: SplashPage(),
)
```

### Scaffold

```dart
Scaffold(
  appBar: AppBar(title: Text("Home")),
)
```

### TextField

```dart
TextField(
  controller: emailController,
)
```

### ElevatedButton

```dart
ElevatedButton(
  onPressed: login,
  child: Text("Login"),
)
```

### ListView

```dart
ListView.builder(
  itemCount: data.length,
  itemBuilder: (context, index) {
    return Text(data[index].nama);
  },
)
```

### Navigator

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => HomePage()),
);
```

### FutureBuilder

```dart
FutureBuilder(
  future: getData(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return Text("Data Loaded");
  },
)
```

## State Management

Menggunakan:

* setState

## Navigation

* Navigator.push
* Navigator.pushReplacement

## Environment Configuration

Menggunakan file `.env`:

* SUPABASE_URL=your_url
* SUPABASE_ANON_KEY=your_key

Menggunakan package:

* flutter_dotenv

API Key tidak ditulis langsung di dalam kode.

## Struktur Folder

<img width="222" height="313" alt="image" src="https://github.com/user-attachments/assets/9d19150b-ab9f-4998-a2fd-0fc8e2483eff" />

## Package yang Digunakan

* supabase_flutter
* flutter_dotenv

## Alur Aplikasi

### 🖥️ Tampilan 1 – Splash Screen

> <img width="718" height="1600" alt="WhatsApp Image 2026-04-20 at 17 00 24" src="https://github.com/user-attachments/assets/cbb2d24c-f251-468e-b139-f56912ac7687" />

---

Halaman pertama yang muncul saat aplikasi dibuka adalah splash screen yang menampilkan identitas aplikasi Studio Podcast Fakultas Ekonomi dan Bisnis Universitas Mulawarman. Pada tampilan ini, pengguna diperkenalkan dengan branding aplikasi melalui logo mikrofon yang melambangkan aktivitas podcast. Selain sebagai pembuka, halaman ini juga berfungsi memberikan kesan awal yang profesional serta menjadi transisi sebelum pengguna masuk ke halaman utama aplikasi.

--- 


### 🔐 Tampilan 2 – Halaman Login

> <img width="718" height="1600" alt="image" src="https://github.com/user-attachments/assets/4e890430-499d-45c5-9e13-1b8c80bb1a07" />

Setelah melewati splash screen, pengguna akan diarahkan ke halaman login. Pada halaman ini, pengguna diminta untuk memasukkan email dan kata sandi untuk dapat mengakses sistem. Desain yang digunakan cukup sederhana dan fokus, sehingga memudahkan pengguna dalam melakukan proses login. Jika pengguna belum memiliki akun, tersedia opsi “Daftar” yang akan mengarahkan ke halaman registrasi. Halaman ini menjadi gerbang utama untuk memastikan bahwa hanya pengguna yang terdaftar yang dapat masuk ke dalam sistem.


### 📝 Tampilan 3 – Halaman Register

> <img width="718" height="1600" alt="image" src="https://github.com/user-attachments/assets/ad35adb4-07db-48a7-a44e-1c88b92b2f62" />

--- 

Halaman register digunakan oleh pengguna baru untuk membuat akun sebelum dapat menggunakan aplikasi. Pengguna diminta mengisi beberapa data seperti nama lengkap, email aktif, kata sandi, dan konfirmasi kata sandi. Proses ini dilengkapi dengan validasi sederhana seperti minimal panjang password agar keamanan akun tetap terjaga. Setelah berhasil mendaftar, pengguna dapat kembali ke halaman login untuk masuk ke sistem. Halaman ini berperan penting dalam menambah pengguna baru dan memastikan data pengguna tersimpan dengan baik.

--- 

