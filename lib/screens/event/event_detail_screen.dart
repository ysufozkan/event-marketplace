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
    final primary = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Registration Successful!'),
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
              'Your Ticket Code',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                reg.ticketCode,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primary,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Show this code at the event entrance',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final primary = Theme.of(context).colorScheme.primary;
    final dateStr =
        DateFormat('d MMMM yyyy, EEEE', 'en_US').format(e.date);
    final timeStr = DateFormat('HH:mm', 'en_US').format(e.date);
    final capacityPct =
        e.capacity > 0 ? e.registeredCount / e.capacity : 0.0;

    final isRegistered = _registration != null;
    final auth = context.watch<AuthProvider>();

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
                    color: primary.withValues(alpha: 0.1)),
                errorWidget: (context, url, error) => Container(
                  color: primary.withValues(alpha: 0.1),
                  child: Icon(Icons.image_outlined,
                      color: primary, size: 56),
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
                              : primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.isFree
                              ? 'Free'
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
                    subtitle: 'Venue',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${e.registeredCount} / ${e.capacity} people',
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
                        e.isFull ? AppColors.error : primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  e.isFull
                      ? const Text('Capacity full',
                          style: TextStyle(
                              color: AppColors.error, fontSize: 12))
                      : Text('${e.spotsLeft} spots left',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                  const SizedBox(height: 24),
                  const Text(
                    'About This Event',
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
        child: auth.isOrganizer
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Organizers cannot register for events',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : _checkingRegistration
                ? Center(
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 2),
                      ),
                    ),
                  )
                : isRegistered
                    ? _RegisteredBanner(
                        ticketCode: _registration!.ticketCode)
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
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : Text(e.isFull
                                  ? 'Sold Out'
                                  : 'Register for Event'),
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
                'Registered',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 14,
                ),
              ),
              Text(
                'Ticket code: $ticketCode',
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
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color = switch (category) {
      'Technology' => const Color(0xFF0D9488),
      'Music' => const Color(0xFFEC4899),
      'Sports' => const Color(0xFF16A34A),
      'Art' => const Color(0xFFF59E0B),
      'Food' => const Color(0xFFEF4444),
      _ => primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
