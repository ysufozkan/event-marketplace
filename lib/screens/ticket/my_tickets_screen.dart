import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/registration_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/registration_provider.dart';
import '../../core/constants/app_colors.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final Stream<List<RegistrationModel>> _stream;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    _stream = context
        .read<RegistrationProvider>()
        .getUserRegistrations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'My Tickets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Events you registered for',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RegistrationModel>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 56, color: AppColors.error),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load tickets',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  final tickets = snapshot.data ?? [];

                  if (tickets.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 72,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tickets yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start attending events!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: tickets.length,
                    itemBuilder: (context, i) =>
                        _TicketCard(registration: tickets[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final RegistrationModel registration;
  const _TicketCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final primary = Theme.of(context).colorScheme.primary;
    final dateStr =
        DateFormat('d MMM yyyy', 'en_US').format(r.eventDate);
    final timeStr = DateFormat('HH:mm', 'en_US').format(r.eventDate);
    final isPast = r.eventDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image + status
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: r.eventImageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: isPast ? Colors.black38 : null,
                  colorBlendMode: isPast ? BlendMode.darken : null,
                  placeholder: (context, url) => Container(
                    height: 110,
                    color: primary.withValues(alpha: 0.1),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 110,
                    color: primary.withValues(alpha: 0.1),
                    child: Icon(Icons.image_outlined,
                        color: primary, size: 36),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.black54
                        : AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPast ? 'Past' : 'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Dashed divider
          _DashedDivider(),

          // Ticket body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.eventTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: '$dateStr · $timeStr',
                ),
                const SizedBox(height: 6),
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: r.eventLocation,
                ),
                const SizedBox(height: 14),

                // Ticket code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded,
                          color: primary, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ticket Code',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            r.ticketCode,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primary,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: r.ticketCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ticket code copied'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.copy_rounded,
                            color: primary, size: 20),
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Registered on: ${DateFormat('d MMM yyyy, HH:mm', 'en_US').format(r.purchasedAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: CustomPaint(
        size: const Size(double.infinity, 20),
        painter: _DashedLinePainter(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.5;

    const circleRadius = 10.0;
    final centerY = size.height / 2;

    // Left notch
    canvas.drawCircle(Offset(-circleRadius / 2, centerY),
        circleRadius, Paint()..color = const Color(0xFFF3F4F6));
    // Right notch
    canvas.drawCircle(
        Offset(size.width + circleRadius / 2, centerY),
        circleRadius,
        Paint()..color = const Color(0xFFF3F4F6));

    // Dashed line
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = circleRadius * 0.6;
    while (startX < size.width - circleRadius * 0.6) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
