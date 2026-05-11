import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';
import '../services/storage_service.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late String _category;
  late DateTime _date;
  String? _accountId;
  String? _imagePath; // raw source path from picker, or existing filename
  bool _isExistingImage = false; // true if _imagePath is an existing stored filename
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _type = widget.existing!.type;
      _amountCtrl = TextEditingController(text: widget.existing!.amount.toStringAsFixed(0));
      _noteCtrl = TextEditingController(text: widget.existing!.note);
      _category = widget.existing!.category;
      _date = widget.existing!.date;
      _accountId = widget.existing!.accountId;
      if (widget.existing!.imagePath != null) {
        _imagePath = widget.existing!.imagePath;
        _isExistingImage = true;
      }
    } else {
      _type = TransactionType.expense;
      _amountCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      final defaultCats = CategoryService.instance.getByType(TransactionType.expense);
      _category = defaultCats.isNotEmpty ? defaultCats.first.name : '餐饮';
      _date = DateTime.now();
      final accounts = AccountService.instance.all;
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('小票', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_imagePath != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isExistingImage
                    ? Image.file(
                        StorageService.instance.getImageFile(_imagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildAddButton(),
                      )
                    : Image.file(
                        File(_imagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: _removeImage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          )
        else
          _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 28),
            const SizedBox(height: 4),
            Text('添加小票', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (xFile != null) {
      setState(() {
        _imagePath = xFile.path;
        _isExistingImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _isExistingImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑账单' : '记一笔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            Row(
              children: [
                _TypeBtn(
                  label: '支出', selected: _type == TransactionType.expense,
                  color: Colors.red, onTap: () => setState(() => _type = TransactionType.expense),
                ),
                const SizedBox(width: 12),
                _TypeBtn(
                  label: '收入', selected: _type == TransactionType.income,
                  color: Colors.green, onTap: () => setState(() => _type = TransactionType.income),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '¥ ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 36),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Category
            const Text('分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CategorySelector(
              type: _type,
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // Account
            const Text('账户', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AccountSelector(
              selectedId: _accountId,
              onSelected: (id) => setState(() => _accountId = id),
            ),
            const SizedBox(height: 20),

            // Note
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: '备注（可选）',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Receipt image picker
            _buildImageSection(),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: Text(DateFormat('yyyy/MM/dd').format(_date)),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => _submit(),
                style: FilledButton.styleFrom(
                  backgroundColor: _type == TransactionType.expense ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? '保存修改' : '添加账单', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    String? finalImagePath;
    if (_imagePath != null) {
      if (_isExistingImage) {
        // Reuse existing stored image
        finalImagePath = _imagePath;
      } else {
        // Copy new picked image to storage
        try {
          finalImagePath = await StorageService.instance.saveImage(_imagePath!);
        } catch (_) {
          // If image copy fails, continue without it
        }
      }
    }

    final t = Transaction(
      id: widget.existing?.id,
      type: _type,
      amount: amount,
      category: _category,
      note: _noteCtrl.text,
      date: _date,
      accountId: _accountId,
      createdAt: widget.existing?.createdAt,
      imagePath: finalImagePath,
    );
    if (!mounted) return;
    Navigator.pop(context, t);
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: selected ? color : Colors.grey,
            )),
          ),
        ),
      ),
    );
  }
}
