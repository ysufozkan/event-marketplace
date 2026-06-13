import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/registration_provider.dart';
import '../../core/constants/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  RegistrationModel? _registration;
  bool _checkingRegistration = true;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    try {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId == null) {
        if (mounted) setState(() => _checkingRegistration = false);
        return;
      }
      final reg = await context
          .read<RegistrationProvider>()
          .getRegistration(userId, widget.event.id);
      if (mounted) {
        setState(() {
          _registration = reg;
          _checkingRegistration = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingRegistration = false);
    }
  }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    final regProvider = context.read<RegistrationProvider>();

    if (auth.user == null) return;

    final reg = await regProvider.register(
      userId: auth.user!.uid,
      userName: auth.user!.name,
      event: widget.event,
    );

    if (!mounted) return;

    if (reg != null) {
      setState(() => _registration = reg);
      _showTicketDialog(reg);
    } else if (regProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regProvider.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      regProvider.clearError();
    }
  }

  void _showTicketDialog(RegistrationModel reg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Kayıt Başarılı!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Bilet Kodun',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                reg.ticketCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu kodu etkinlik girişinde göster',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final dateStr =
        DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(e.date);
    final timeStr = DateFormat('HH:mm', 'tr_TR').format(e.date);
    final capacityPct =
        e.capacity > 0 ? e.registeredCount / e.capacity : 0.0;

    final isRegistered = _registration != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      size: 16, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: e.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1)),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 56),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryBadge(category: e.category),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: e.isFree
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.isFree
                              ? 'Ücretsiz'
                              : '₺${e.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        e.organizerName,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: dateStr,
                    subtitle: timeStr,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    title: e.location,
                    subtitle: 'Etkinlik Yeri',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Katılım Durumu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${e.registeredCount} / ${e.capacity} kişi',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: capacityPct.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(
                        e.isFull ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  e.isFull
                      ? const Text('Kontenjan doldu',
                          style: TextStyle(
                              color: AppColors.error, fontSize: 12))
                      : Text('${e.spotsLeft} yer kaldı',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                  const SizedBox(height: 24),
                  const Text(
                    'Etkinlik Hakkında',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -4)),
          ],
        ),
        child: _checkingRegistration
            ? const Center(
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              )
            : isRegistered
                ? _RegisteredBanner(ticketCode: _registration!.ticketCode)
                : Consumer<RegistrationProvider>(
                    builder: (context, reg, _) => ElevatedButton(
                      onPressed:
                          (e.isFull || reg.isLoading) ? null : _register,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor:
                            const Color(0xFFD1D5DB),
                        disabledForegroundColor:
                            AppColors.textSecondary,
                      ),
                      child: reg.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(e.isFull
                              ? 'Kontenjan Dolu'
                              : 'Etkinliğe Kayıt Ol'),
                    ),
                  ),
      ),
    );
  }
}

class _RegisteredBanner extends StatelessWidget {
  final String ticketCode;
  const _RegisteredBanner({required this.ticketCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kayıtlısınız',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 14,
                ),
              ),
              Text(
                'Bilet kodu: $ticketCode',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category) {
      case 'Teknoloji':
        return const Color(0xFF3B82F6);
      case 'Müzik':
        return const Color(0xFFEC4899);
      case 'Spor':
        return const Color(0xFF10B981);
      case 'Sanat':
        return const Color(0xFFF59E0B);
      case 'Yemek':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: _color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
