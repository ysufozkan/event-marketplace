import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;
  final _eventService = EventService();

  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _existingImageUrl;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  static const _categories = [
    'Teknoloji', 'Müzik', 'Spor', 'Sanat', 'Yemek',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e.title);
    _descController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.location);
    _priceController =
        TextEditingController(text: e.price.toStringAsFixed(0));
    _capacityController =
        TextEditingController(text: e.capacity.toString());
    _selectedCategory = _categories.contains(e.category)
        ? e.category
        : _categories.first;
    _selectedDate = e.date;
    _existingImageUrl = e.imageUrl.isNotEmpty ? e.imageUrl : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageFile = file;
      _imageBytes = bytes;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String imageUrl = _existingImageUrl ?? '';
      if (_imageFile != null) {
        imageUrl = await _eventService.uploadImage(_imageFile!);
      }

      await _eventService.updateEvent(widget.event.id, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'date': _selectedDate,
        'price': double.tryParse(_priceController.text) ?? 0,
        'capacity': int.tryParse(_capacityController.text) ?? widget.event.capacity,
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlik güncellendi!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinliği Düzenle'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageBytes != null)
                          Image.memory(_imageBytes!, fit: BoxFit.cover)
                        else if (_existingImageUrl != null)
                          CachedNetworkImage(
                            imageUrl: _existingImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.primary
                                    .withValues(alpha: 0.08)),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.primary),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              const Text('Fotoğraf Ekle',
                                  style:
                                      TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Değiştir',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const _Label('Etkinlik Adı'),
              TextFormField(
                controller: _titleController,
                validator: (v) => Validators.required(v, 'Etkinlik adı'),
                decoration:
                    const InputDecoration(hintText: 'Etkinlik adı'),
              ),
              const SizedBox(height: 16),

              const _Label('Açıklama'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                validator: (v) => Validators.required(v, 'Açıklama'),
                decoration: const InputDecoration(
                  hintText: 'Etkinlik hakkında bilgi...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              const _Label('Kategori'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              const _Label('Konum'),
              TextFormField(
                controller: _locationController,
                validator: (v) => Validators.required(v, 'Konum'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              const _Label('Tarih ve Saat'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
                            .format(_selectedDate),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Ücret (₺)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                              hintText: '0', prefixText: '₺ '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Kapasite'),
                        TextFormField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Gerekli';
                            }
                            if (int.tryParse(v) == null ||
                                int.parse(v) < 1) {
                              return 'Geçersiz';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                              hintText: '100', suffixText: 'kişi'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Güncelle'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
