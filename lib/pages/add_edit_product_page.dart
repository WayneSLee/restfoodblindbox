// lib/pages/add_edit_product_page.dart

import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/product_model.dart';
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

class AddEditProductPage extends StatefulWidget {
  final String storeId;
  final Product? productToEdit;

  const AddEditProductPage({
    super.key,
    required this.storeId,
    this.productToEdit,
  });

  bool get isEditing => productToEdit != null;

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  // --- vvv 這是本次新增的狀態變數 vvv ---
  TimeOfDay? _pickupStartTime;
  TimeOfDay? _pickupEndTime;
  // --- ^^^ 新增到此結束 ^^^ ---

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final product = widget.productToEdit!;
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _descriptionController.text = product.description;
      _quantityController.text = product.quantity.toString();
      _imageUrl = product.imageUrl;

      // --- vvv 這是本次新增的邏輯 vvv ---
      // 如果是編輯模式，且商品有儲存時間，則解析並設定
      if (product.pickupStartTime != null) {
        final parts = product.pickupStartTime!.split(':');
        _pickupStartTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (product.pickupEndTime != null) {
        final parts = product.pickupEndTime!.split(':');
        _pickupEndTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      // --- ^^^ 新增到此結束 ^^^ ---
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    // ... 此方法維持不變 ...
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

  // --- vvv 這是本次新增的方法 vvv ---
  // 用於顯示時間選擇器
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime
        ? (_pickupStartTime ?? TimeOfDay.now())
        : (_pickupEndTime ?? TimeOfDay.now());
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _pickupStartTime = pickedTime;
        } else {
          _pickupEndTime = pickedTime;
        }
      });
    }
  }
  // --- ^^^ 新增到此結束 ^^^ ---

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null || _imageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先上傳一張商品照片')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final productData = {
        "name": _nameController.text,
        "price": double.tryParse(_priceController.text) ?? 0.0,
        "description": _descriptionController.text,
        "quantity": int.tryParse(_quantityController.text) ?? 0,
        "imageUrl": _imageUrl,
        // --- vvv 這是本次新增的邏輯 vvv ---
        // 將選擇的時間格式化後加入要提交的資料中
        "pickupStartTime": _pickupStartTime?.to24HourFormat(),
        "pickupEndTime": _pickupEndTime?.to24HourFormat(),
        // --- ^^^ 新增到此結束 ^^^ ---
      };

      try {
        if (widget.isEditing) {
          await ApiService.updateProduct(widget.productToEdit!.id, productData);
        } else {
          await ApiService.createProduct(widget.storeId, productData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('商品已成功${widget.isEditing ? '更新' : '新增'}！')),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失敗: $e')),
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
        title: Text(widget.isEditing ? '編輯商品' : '新增商品'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... 其他 TextFormField 維持不變 ...
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '商品名稱'),
                validator: (v) => v!.isEmpty ? '請輸入商品名稱' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '價格'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? '請輸入價格' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: '數量'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '請輸入數量' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? '請輸入描述' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- vvv 這是本次新增的 UI vvv ---
              const SizedBox(height: 16),
              const Text('自取時段 (選填)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('開始時間'),
                trailing: Text(
                  _pickupStartTime?.format(context) ?? '未設定',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => _selectTime(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('結束時間'),
                trailing: Text(
                  _pickupEndTime?.format(context) ?? '未設定',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 16),
              const Divider(),
              // --- ^^^ 新增到此結束 ^^^ ---

              const SizedBox(height: 24),
              const Text('商品照片',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // ... 圖片上傳 UI 維持不變 ...
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _imageUrl == null || _imageUrl!.isEmpty
                      ? const Text('尚未上傳照片', style: TextStyle(color: Colors.grey))
                      : Image.network(_imageUrl!,
                      fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 8),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                onPressed: _handleImageUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('更換並上傳照片'),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(widget.isEditing ? '儲存變更' : '上架商品'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}