import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_bloc.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_event.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/pages/chat_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- 1. 引入 url_launcher 套件

final _currencyFormatter =
NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);
final _dateFormatter = DateFormat('yyyy/MM/dd HH:mm');

class OrderDetailPage extends StatefulWidget {
  final Order order;
  final String userRole;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.userRole,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isProcessing = false;

  // --- vvv 2. 新增啟動地圖導航的方法 vvv ---
  Future<void> _launchMaps(BuildContext context, String address) async {
    // 將地址進行 URL 編碼，以處理特殊字元
    final encodedAddress = Uri.encodeComponent(address);
    // 建立一個通用的 Google Maps 搜尋 URL
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(googleMapsUrl)) {
      // 嘗試啟動 URL
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟地圖應用程式')),
        );
      }
    }
  }
  // --- ^^^ 新增結束 ^^^ ---

  Future<void> _updateOrderStatus(Future<void> Function(String) apiCall) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await apiCall(widget.order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訂單狀態已更新！'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConsumer = widget.userRole == 'consumer';
    final bool isStore = widget.userRole == 'store';
    final bool canStoreManage =
        isStore && widget.order.status.toLowerCase() == 'pending';
    final bool showQrCode =
        isConsumer && widget.order.status.toLowerCase() == 'accepted';

    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showQrCode)
              Center(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: QrImageView(
                        data: widget.order.id,
                        version: QrVersions.auto,
                        size: 220.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('請出示此 QR Code 給店家掃描取貨',
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            _buildInfoSection('店家名稱', widget.order.storeName),
            _buildInfoSection('訂單編號', widget.order.id),
            _buildInfoSection(
                '下單時間', _dateFormatter.format(widget.order.createdAt)),

            const Divider(height: 32),

            const Text('訂單內容',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.name} x ${item.quantity}'),
                  Text(_currencyFormatter.format(item.price * item.quantity)),
                ],
              ),
            )).toList(),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('總計: ', style: TextStyle(fontSize: 18)),
                Text(
                  _currencyFormatter.format(widget.order.totalPrice),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isConsumer)
              _buildContactButton(
                context,
                '聯絡店家',
                    () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChatPage(
                    orderId: widget.order.id,
                    recipientName: widget.order.storeName,
                    chatContext: 'order',
                  ),
                )),
              ),

            if (isStore)
              _buildContactButton(
                context,
                '聯絡顧客',
                    () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChatPage(
                    orderId: widget.order.id,
                    recipientName: widget.order.customerProfile?.name ?? '顧客',
                    chatContext: 'order',
                  ),
                )),
              ),

            // --- vvv 3. 新增導航按鈕的 UI 邏輯 vvv ---
            const SizedBox(height: 8),
            if (isConsumer && widget.order.status.toLowerCase() == 'accepted')
              ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('導航至店家'),
                onPressed: () => _launchMaps(context, widget.order.storeAddress),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            // --- ^^^ 新增結束 ^^^ ---

            const SizedBox(height: 16),

            if (canStoreManage)
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('拒絕訂單'),
                        onPressed: () => _updateOrderStatus(ApiService.rejectOrder),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                      )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('接受訂單'),
                        onPressed: () => _updateOrderStatus(ApiService.acceptOrder),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.chat_bubble_outline),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}