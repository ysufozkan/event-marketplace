import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import '../../core/constants/app_colors.dart';
import 'edit_event_screen.dart';
import 'attendees_screen.dart';

class ManageEventsScreen extends StatelessWidget {
  final UserModel organizer;
  const ManageEventsScreen({super.key, required this.organizer});

  @override
  Widget build(BuildContext context) {
    final service = EventService();
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
                'My Events',
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
                'Manage your created events',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: service.getEventsByOrganizer(organizer.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 72,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "You haven't created any events yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use the + button on the Explore tab',
                            style: TextStyle(
                              fontSize: 13,
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
                    itemCount: events.length,
                    itemBuilder: (context, i) =>
                        _EventManageCard(event: events[i], service: service),
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

class _EventManageCard extends StatelessWidget {
  final EventModel event;
  final EventService service;
  const _EventManageCard({required this.event, required this.service});

  Future<void> _confirmDeactivate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Event'),
        content: Text(
            'Are you sure you want to deactivate "${event.title}"? No new registrations will be allowed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await service.deactivateEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deactivated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dateStr =
        DateFormat('d MMM yyyy, HH:mm', 'en_US').format(event.date);
    final capacityPct = event.capacity > 0
        ? event.registeredCount / event.capacity
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: event.isActive ? null : Colors.black38,
                  colorBlendMode:
                      event.isActive ? null : BlendMode.darken,
                  placeholder: (_, __) => Container(
                    height: 120,
                    color: primary.withValues(alpha: 0.08),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: primary.withValues(alpha: 0.08),
                    child: Icon(Icons.image_outlined,
                        color: primary, size: 36),
                  ),
                ),
              ),
              if (!event.isActive)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.people_outline_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${event.registeredCount}/${event.capacity}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: capacityPct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(
                      event.isFull ? AppColors.error : primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.people_rounded,
                      label: 'Attendees',
                      color: primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendeesScreen(event: event),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: const Color(0xFF0D9488),
                      onTap: event.isActive
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditEventScreen(event: event),
                                ),
                              )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.visibility_off_rounded,
                      label: 'Deactivate',
                      color: AppColors.error,
                      onTap: event.isActive
                          ? () => _confirmDeactivate(context)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xFFF3F4F6)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled
                  ? const Color(0xFFE5E7EB)
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isDisabled ? AppColors.textSecondary : color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? AppColors.textSecondary : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
