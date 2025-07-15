import 'package:flutter/material.dart';
import 'package:restfoodblindbox/services/support_service.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    // 驗證表單
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);

      try {
        // 呼叫我們之前建立的 SupportService
        await SupportService().createNewTicket(
          _subjectController.text,
          _messageController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('您的問題已成功送出！客服人員將會盡快與您聯繫。'),
              backgroundColor: Colors.green,
            ),
          );
          // 成功送出後，自動返回上一頁
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('傳送失敗: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聯絡客服'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '主旨',
                hintText: '例如：關於訂單 #123 的問題',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? '請輸入主旨' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: '問題描述',
                hintText: '請在此詳細描述您遇到的問題...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (value) =>
              value == null || value.isEmpty ? '請輸入問題描述' : null,
            ),
            const SizedBox(height: 24),
            if (_isSending)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _submitTicket,
                icon: const Icon(Icons.send),
                label: const Text('送出問題'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}