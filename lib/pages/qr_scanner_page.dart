import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/pages/order_detail_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  // 手機掃描器控制器
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false; // 用於防止重複處理

  // 掃描成功後的處理邏輯
  Future<void> _handleQrCode(String orderId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. 先呼叫完成訂單的 API
      await ApiService.completeOrder(orderId);

      if (mounted) {
        // 2. 接著，呼叫我們之前建立的 API，來獲取這筆剛完成的訂單資料
        final Order completedOrder = await ApiService.fetchOrderById(orderId);

        // 3. 成功獲取後，先關閉掃描頁，再跳轉到訂單詳情頁
        //    我們使用 pushReplacement 來避免使用者可以返回到掃描頁
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            order: completedOrder,
            userRole: 'store', // 以店家身份查看
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        // 錯誤處理維持不變
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('核銷失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 為了避免在跳轉過程中出錯，我們延遲一點再重設處理狀態
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('掃描取貨 QR Code')),
      body: Stack(
        children: [
          // 相機預覽畫面
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? qrCodeValue = barcodes.first.rawValue;
                if (qrCodeValue != null) {
                  print("掃描到 QR Code: $qrCodeValue");
                  _handleQrCode(qrCodeValue);
                }
              }
            },
          ),
          // 掃描框提示 UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
