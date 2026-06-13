import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';

class CreateEventScreen extends StatefulWidget {
  final UserModel organizer;
  const CreateEventScreen({super.key, required this.organizer});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _capacityController = TextEditingController();
  final _eventService = EventService();

  String _selectedCategory = 'Teknoloji';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  static const _categories = [
    'Teknoloji',
    'Müzik',
    'Spor',
    'Sanat',
    'Yemek',
  ];

  static const _defaultImages = {
    'Teknoloji':
        'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
    'Müzik':
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800',
    'Spor':
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800',
    'Sanat':
        'https://images.unsplash.com/photo-1531243269054-5ebf6f34081e?w=800',
    'Yemek':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
  };

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
          colorScheme:
              ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String imageUrl;
      if (_imageFile != null) {
        imageUrl = await _eventService.uploadImage(_imageFile!);
      } else {
        imageUrl = _defaultImages[_selectedCategory] ??
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800';
      }

      final event = EventModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        organizerId: widget.organizer.uid,
        organizerName: widget.organizer.name,
        imageUrl: imageUrl,
        location: _locationController.text.trim(),
        date: _selectedDate,
        price: double.tryParse(_priceController.text) ?? 0,
        capacity: int.tryParse(_capacityController.text) ?? 50,
        registeredCount: 0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _eventService.createEvent(event);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlik başarıyla oluşturuldu!'),
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
        title: const Text('Etkinlik Oluştur'),
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
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(_imageBytes!,
                                  fit: BoxFit.cover),
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
                                            color: Colors.white,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48,
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Fotoğraf Ekle (isteğe bağlı)',
                              style: TextStyle(
                                color:
                                    AppColors.primary.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seçilmezse kategori görseli kullanılır',
                              style: TextStyle(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              const _Label('Etkinlik Adı'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.required(v, 'Etkinlik adı'),
                decoration: const InputDecoration(
                    hintText: 'Örn: Flutter Workshop 2025'),
              ),
              const SizedBox(height: 16),

              const _Label('Açıklama'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.required(v, 'Açıklama'),
                decoration: const InputDecoration(
                  hintText: 'Etkinlik hakkında detaylı bilgi...',
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
                  hintText: 'Örn: Mühendislik Binası A-101',
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
                    border:
                        Border.all(color: const Color(0xFFE5E7EB)),
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
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: '₺ ',
                          ),
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
                              return 'Kapasite gerekli';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n < 1) {
                              return 'Geçersiz sayı';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: '100',
                            suffixText: 'kişi',
                          ),
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
                    : const Text('Etkinlik Oluştur'),
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
