import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/image_upload_service.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

// 擴充方法，方便將 TimeOfDay 轉為 "HH:mm" 格式
extension TimeOfDayExtension on TimeOfDay {
  String to24HourFormat() {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }
}

class EditStoreInfoPage extends StatefulWidget {
  final String storeId;

  const EditStoreInfoPage({super.key, required this.storeId});

  @override
  State<EditStoreInfoPage> createState() => _EditStoreInfoPageState();
}

class _EditStoreInfoPageState extends State<EditStoreInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late Future<Store> _storeFuture;

  // Form Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _phoneController = TextEditingController();

  // State variables
  String? _imageUrl;
  bool _isUploading = false;
  List<String> _tags = [];
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  Set<int> _daysOpen = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _storeFuture = _fetchAndPopulateStoreData();
  }

  Future<Store> _fetchAndPopulateStoreData() async {
    final store = await ApiService.fetchStoreById(widget.storeId);
    if (mounted) {
      _nameController.text = store.name;
      _descriptionController.text = store.description;
      _addressController.text = store.address;
      _imageUrl = store.imageUrl;
      _tags = store.tags;
      _daysOpen = store.daysOpen.toSet();
      _phoneController.text = store.phone ?? '';

      if (store.openingTime != null) {
        final parts = store.openingTime!.split(':');
        _openingTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (store.closingTime != null) {
        final parts = store.closingTime!.split(':');
        _closingTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    return store;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

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
      };

      try {
        await ApiService.updateStoreInfo(widget.storeId, storeData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('店家資訊已成功更新！'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('儲存失敗: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯店家資訊'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
              tooltip: '儲存',
            ),
        ],
      ),
      body: FutureBuilder<Store>(
        future: _storeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('無法載入店家資料: ${snapshot.error}'));
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: '店家名稱', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? '請輸入店家名稱' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                      labelText: '店家聯絡電話', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                      labelText: '店家地址', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? '請輸入店家地址' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: '店家描述', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? '請輸入店家描述' : null,
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildTagsSection(),
                const Divider(),
                _buildTimeSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveForm,
                  child: const Text('儲存變更'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店家照片',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Center(
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              image: _imageUrl != null
                  ? DecorationImage(
                image: NetworkImage(_imageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _imageUrl == null
                ? const Center(
                child: Text('尚未上傳照片', style: TextStyle(color: Colors.grey)))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        _isUploading
            ? const LinearProgressIndicator()
            : SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleImageUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('更換照片'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('店家標籤',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
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
                  hintText: '輸入後按右方按鈕新增',
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
        const Text('營業時間',
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
        const Text('營業日',
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