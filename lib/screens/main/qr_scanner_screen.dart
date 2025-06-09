import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:nompangs/helpers/deeplink_helper.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;
  bool _scanCompletedAndNavigating = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    print('[QRScannerScreen][${defaultTargetPlatform.name}] initState');
  }

  @override
  void dispose() {
    print('[QRScannerScreen][${defaultTargetPlatform.name}] dispose');
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String code) async {
    if (!mounted) return;
    // 이 함수가 호출되면 무조건 처리 중 상태로 변경
    // onDetect에서 이미 중복 호출을 방지하고 있으므로, 여기서의 _isProcessing 체크는 UI 업데이트용
    setState(() { _isProcessing = true; });


    Map<String, dynamic>? chatData;
    String? uuidFromQR;

    try {
      final uri = Uri.tryParse(code);
      if (uri != null) {
        uuidFromQR = uri.queryParameters['id'];
      }

      if (uuidFromQR != null) {
        chatData = await DeepLinkHelper.processCharacterData(uuidFromQR)
            .timeout(const Duration(seconds: 20), onTimeout: () {
          print('[QRScanner][${defaultTargetPlatform.name}] _handleQRCode: DeepLinkHelper.processCharacterData 타임아웃.');
          if (mounted) _showError('캐릭터 정보 처리 시간이 초과되었습니다.');
          return null;
        });
      } else {
        // uuidFromQR이 null이면 사용자에게 알림
        if (mounted) _showError('QR 코드에서 UUID를 읽을 수 없습니다.');
      }

      if (chatData != null && mounted) {
        _scanCompletedAndNavigating = true; // 내비게이션 시작 플래그
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              characterName: chatData!['characterName'] as String,
              personalityTags: chatData['personalityTags'] as List<String>,
              greeting: chatData['greeting'] as String?,
            ),
          ),
        );
        return; 
      } else {
          if (mounted && uuidFromQR != null && chatData == null) {
        }
      }
    } catch (e, s) {
      print('[QRScanner][${defaultTargetPlatform.name}] _handleQRCode: 처리 중 오류: $e, Stack: $s');
      if (mounted) _showError('QR 코드 처리 중 오류가 발생했습니다.');
    } finally {
      // 내비게이션이 발생하지 않았고, 위젯이 여전히 마운트된 경우에만 _isProcessing 상태를 해제
      if (mounted && !_scanCompletedAndNavigating) {
        setState(() { _isProcessing = false; });
      }
    }
  } 

  void _showError(String message) {
    if (!mounted) return;
    print('[QRScannerScreen_showError][${defaultTargetPlatform.name}] 오류: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'QR 코드 스캔',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (!mounted || _isProcessing || _scanCompletedAndNavigating) {
                      return;
                    }
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final String scannedCode = barcodes.first.rawValue!;
                      _handleQRCode(scannedCode.trim());
                    }
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          SizedBox(height: 16),
                          Text('QR 코드 처리 중...', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              '캐릭터 QR 코드를 스캔해주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}