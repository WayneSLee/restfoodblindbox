// lib/pages/store_registration_page.dart

import 'package:flutter/material.dart';
import 'package:restfoodblindbox/pages/store_dashboard_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/image_upload_service.dart';

// 擴充方法，方便將 TimeOfDay 轉為 "HH:mm" 格式
extension TimeOfDayExtension on TimeOfDay {
  String to24HourFormat() {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }
}


class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // --- vvv 這是更新後的 Controller 和狀態變數 vvv ---
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = false;
  List<String> _tags = [];
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  Set<int> _daysOpen = {};
  // --- ^^^ 更新到此結束 ^^^ ---

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    setState(() => _isUploading = true);
    final service = ImageUploadService();
    final imageUrl = await service.pickAndUploadImage(context);

    if (imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
      });
    }
    setState(() => _isUploading = false);
  }

  // --- vvv 這是新增的輔助方法 vvv ---
  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final initialTime = isOpeningTime
        ? (_openingTime ?? TimeOfDay.now())
        : (_closingTime ?? TimeOfDay.now());
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = pickedTime;
        } else {
          _closingTime = pickedTime;
        }
      });
    }
  }

  void _addTag() {
    final tagText = _tagInputController.text.trim();
    if (tagText.isNotEmpty && !_tags.contains(tagText)) {
      setState(() {
        _tags.add(tagText);
      });
      _tagInputController.clear();
    }
  }
  // --- ^^^ 新增到此結束 ^^^ ---

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先上傳一張店家照片')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // --- vvv 這是更新後的店家資料 Map vvv ---
      final storeData = {
        "name": _nameController.text,
        "address": _addressController.text,
        "description": _descriptionController.text,
        "imageUrl": _imageUrl,
        "phone": _phoneController.text,
        "openingTime": _openingTime?.to24HourFormat(),
        "closingTime": _closingTime?.to24HourFormat(),
        "daysOpen": _daysOpen.toList(),
        "tags": _tags,
        // googleMapsUrl 和 rating 由後端處理或給預設值
      };
      // --- ^^^ 更新到此結束 ^^^ ---

      try {
        final newStoreId = await ApiService.createStore(storeData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('店家資料已提交！歡迎加入！')),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => StoreDashboardPage(storeId: newStoreId),
            ),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('提交失敗: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申請成為店家'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '店家名稱', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? '請輸入店家名稱' : null,
              ),
              const SizedBox(height: 16),
              // --- vvv 這是本次修改的核心 vvv ---
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '店家聯絡電話', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? '請輸入店家聯絡電話' : null,
              ),
              // --- ^^^ 修改到此結束 ^^^ ---
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: '店家地址', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? '請輸入店家地址' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '店家描述', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? '請輸入店家描述' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- vvv 這是新增的 UI 區塊 vvv ---
              _buildTagsSection(),
              const Divider(),
              _buildTimeSection(),
              // --- ^^^ 新增到此結束 ^^^ ---

              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('提交申請'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- vvv 以下是從 edit_store_info_page.dart 移植過來的 UI 建立方法 vvv ---
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店家照片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _imageUrl == null
                ? const Text('尚未上傳照片', style: TextStyle(color: Colors.grey))
                : Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
        const SizedBox(height: 8),
        _isUploading
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton.icon(
          onPressed: _handleImageUpload,
          icon: const Icon(Icons.upload_file),
          label: const Text('選擇並上傳照片'),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('店家標籤 (選填)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
              deleteIconColor: Colors.red.shade700,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  labelText: '輸入新標籤',
                  hintText: '例如: 麵包、日式料理',
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addTag,
              tooltip: '新增標籤',
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('營業時間 (選填)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          title: const Text('開店時間'),
          trailing: Text(
            _openingTime?.format(context) ?? '未設定',
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () => _selectTime(context, true),
        ),
        ListTile(
          title: const Text('關店時間'),
          trailing: Text(
            _closingTime?.format(context) ?? '未設定',
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () => _selectTime(context, false),
        ),
        const SizedBox(height: 24),
        const Text('營業日 (選填)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(7, (int index) {
            final dayIndex = index + 1;
            final isSelected = _daysOpen.contains(dayIndex);
            return FilterChip(
              label: Text('週${['一', '二', '三', '四', '五', '六', '日'][index]}'),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _daysOpen.add(dayIndex);
                  } else {
                    _daysOpen.remove(dayIndex);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }
}