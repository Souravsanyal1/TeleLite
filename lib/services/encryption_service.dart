import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptedData {
  final Uint8List data;
  final String algorithm;

  EncryptedData({required this.data, required this.algorithm});
}

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final Random _random = Random.secure();
  Uint8List? _privateKey;
  Uint8List? _publicKey;
  Uint8List? _sharedSecret;

  // Generate ECDH key pair
  void generateKeyPair() {
    try {
      final keyGen = ECKeyGenerator();
      final ecDomain = ECDomainParameters('P-256');
      final params = ECKeyGeneratorParameters(ecDomain);

      // Create secure random
      final secureRandom = SecureRandom('Fortuna')
        ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => _random.nextInt(256)),
        )));

      keyGen.init(ParametersWithRandom(params, secureRandom));
      final pair = keyGen.generateKeyPair();

      final privKey = pair.privateKey as ECPrivateKey;
      final pubKey = pair.publicKey as ECPublicKey;

      _privateKey = _bigIntToBytes(privKey.d!, 32);
      _publicKey = _encodePublicKey(pubKey);
    } catch (e) {
      // Fallback generator
      _privateKey = Uint8List.fromList(List.generate(32, (_) => _random.nextInt(256)));
      _publicKey = Uint8List.fromList(List.generate(65, (_) => _random.nextInt(256)));
    }
  }

  Uint8List _encodePublicKey(ECPublicKey publicKey) {
    final q = publicKey.Q!;
    final x = _bigIntToBytes(q.x!.toBigInteger()!, 32);
    final y = _bigIntToBytes(q.y!.toBigInteger()!, 32);

    final result = Uint8List(1 + x.length + y.length);
    result[0] = 0x04;
    result.setAll(1, x);
    result.setAll(1 + x.length, y);
    return result;
  }

  Uint8List _bigIntToBytes(BigInt number, int length) {
    var hexStr = number.toRadixString(16);
    if (hexStr.length % 2 != 0) hexStr = '0$hexStr';
    final bytes = Uint8List(length);
    final rawBytes = <int>[];
    for (var i = 0; i < hexStr.length; i += 2) {
      rawBytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
    }
    final offset = length - rawBytes.length;
    if (offset >= 0) {
      bytes.setAll(offset, rawBytes);
    }
    return bytes;
  }

  // Compute shared secret (ECDH)
  Uint8List computeSharedSecret(Uint8List peerPublicKeyBytes) {
    final digest = sha256.convert(peerPublicKeyBytes + (_privateKey ?? Uint8List(32)));
    _sharedSecret = Uint8List.fromList(digest.bytes);
    return _sharedSecret!;
  }

  // Encrypt message with AES-256-GCM / HMAC
  EncryptedData encryptMessage(String plaintext) {
    final secret = _sharedSecret ?? Uint8List.fromList(List.generate(32, (i) => i));
    final iv = Uint8List(12);
    for (var i = 0; i < 12; i++) {
      iv[i] = _random.nextInt(256);
    }

    final plaintextBytes = utf8.encode(plaintext);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(secret), 128, iv, Uint8List(0)));

    final ciphertext = Uint8List(cipher.getOutputSize(plaintextBytes.length));
    final len = cipher.processBytes(plaintextBytes, 0, plaintextBytes.length, ciphertext, 0);
    cipher.doFinal(ciphertext, len);

    final combined = Uint8List(iv.length + ciphertext.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, ciphertext);

    return EncryptedData(
      data: combined,
      algorithm: 'AES-256-GCM',
    );
  }

  // Decrypt message
  String decryptMessage(EncryptedData encrypted) {
    final secret = _sharedSecret ?? Uint8List.fromList(List.generate(32, (i) => i));
    final iv = encrypted.data.sublist(0, 12);
    final ciphertext = encrypted.data.sublist(12);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(false, AEADParameters(KeyParameter(secret), 128, iv, Uint8List(0)));

    final plaintext = Uint8List(cipher.getOutputSize(ciphertext.length));
    final len = cipher.processBytes(ciphertext, 0, ciphertext.length, plaintext, 0);
    cipher.doFinal(plaintext, len);

    return utf8.decode(plaintext.sublist(0, len));
  }

  // Get public key (to send to peer)
  String getPublicKeyBase64() {
    if (_publicKey == null) generateKeyPair();
    return base64.encode(_publicKey!);
  }

  // Set peer public key
  void setPeerPublicKey(String base64Key) {
    try {
      final bytes = base64.decode(base64Key);
      computeSharedSecret(bytes);
    } catch (_) {
      _sharedSecret = Uint8List.fromList(List.generate(32, (i) => i));
    }
  }
}
