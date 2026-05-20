import 'package:flutter/services.dart'; // Ditambahkan untuk membaca error platform jika ada
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart'; // Ditambahkan untuk handling pesan dialog Android rilis

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Memeriksa apakah perangkat keras HP mendukung & mengaktifkan sensor sidik jari
  Future<bool> checkBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Menampilkan lembar pemindaian sidik jari bawaan OS Android / iOS
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk masuk ke FEB Studio',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              true, // Memaksa verifikasi jari/wajah, bukan PIN/Pola layar
        ),
        // PERBAIKAN STABILITAS RILIS: Menambahkan strings konfigurasi dialog bawaan Android
        // agar OS tidak bingung merender dialog sistem saat dalam mode rilis terkompresi.
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Otentikasi Biometrik',
            biometricHint: 'Sentuh sensor sidik jari',
            cancelButton: 'Batal',
          ),
        ],
      );
    } on PlatformException catch (e) {
      // Menangkap error spesifik dari hardware Android rilis (misal: sensor kotor/belum didaftarkan)
      print("Eror Biometrik Platform: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      return false;
    }
  }
}
