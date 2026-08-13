import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'nxxs4wxu';
  static const String apiKey = '543461283334664';
  static const String apiSecret = 'uO3-BFg36TDtdqazoLRwSYaZWwQ';

  Future<String?> uploadFile(File file, {bool isVideo = false}) async {
    final resourceType = isVideo ? 'video' : 'image';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
    
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    
    // Cloudinary signature generation:
    // Sort parameters alphabetically, join with '&', append API secret, then SHA-1.
    final stringToSign = 'timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    final signature = digest.toString();

    final request = http.MultipartRequest('POST', url)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final jsonMap = jsonDecode(responseString);
      return jsonMap['secure_url'];
    } else {
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      throw Exception('Failed to upload media to Cloudinary: ${response.statusCode} - $responseString');
    }
  }
}
