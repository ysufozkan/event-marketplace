import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../core/constants/app_colors.dart';
import '../event/event_detail_screen.dart';
import '../event/create_event_screen.dart';
import '../ticket/my_tickets_screen.dart';
import '../organizer/manage_events_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _eventService = EventService();
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _currentTab = 0;

  final _categories = ['All', 'Technology', 'Music', 'Sports', 'Art', 'Food'];

  @override
  void initState() {
    super.initState();
    _eventService.seedEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      floatingActionButton: (_currentTab == 0 && auth.isOrganizer)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateEventScreen(organizer: auth.user!),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
              backgroundColor: primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.clamp(0, 2),
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          if (auth.isOrganizer)
            const BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'My Events',
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number_rounded),
              label: 'My Tickets',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      body: _currentTab == 2
          ? const ProfileScreen()
          : _currentTab == 1
              ? (auth.isOrganizer
                  ? ManageEventsScreen(organizer: auth.user!)
                  : const MyTicketsScreen())
              : Column(
        children: [
          _AppHeader(
            userName: auth.user?.name.split(' ').first ?? '',
            searchController: _searchController,
            onSearch: (q) => setState(() => _searchQuery = q),
            onLogout: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          _CategoryBar(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: (cat) => setState(() => _selectedCategory = cat),
          ),
          Expanded(
            child: _EventGrid(
              eventService: _eventService,
              category: _selectedCategory,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}


class _AppHeader extends StatelessWidget {
  final String userName;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onLogout;

  const _AppHeader({
    required this.userName,
    required this.searchController,
    required this.onSearch,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_rounded,
                      color: primary, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'EventHub',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selected == cat;
            return GestureDetector(
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EventGrid extends StatefulWidget {
  final EventService eventService;
  final String category;
  final String searchQuery;

  const _EventGrid({
    required this.eventService,
    required this.category,
    required this.searchQuery,
  });

  @override
  State<_EventGrid> createState() => _EventGridState();
}

class _EventGridState extends State<_EventGrid> {
  late Stream<List<EventModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.eventService.getEvents(
      category: widget.category == 'All' ? null : widget.category,
    );
  }

  @override
  void didUpdateWidget(_EventGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _stream = widget.eventService.getEvents(
        category: widget.category == 'All' ? null : widget.category,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<List<EventModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primary),
          );
        }

        var events = snapshot.data ?? [];
        if (widget.searchQuery.isNotEmpty) {
          final q = widget.searchQuery.toLowerCase();
          events = events
              .where((e) =>
                  e.title.toLowerCase().contains(q) ||
                  e.location.toLowerCase().contains(q))
              .toList();
        }

        if (events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 56, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No events found',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 230,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) => _EventCard(event: events[index]),
        );
      },
    );
  }
}

class _EventCard extends StatefulWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final primary = Theme.of(context).colorScheme.primary;
    final dateStr = DateFormat('d MMM, HH:mm', 'en_US').format(e.date);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: e),
        ),
      ),
      child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x22000000)
                  : const Color(0x10000000),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: e.imageUrl,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 90,
                      color: primary.withValues(alpha: 0.08),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 90,
                      color: primary.withValues(alpha: 0.08),
                      child: Icon(Icons.image_outlined,
                          color: primary, size: 36),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: e.isFree ? AppColors.success : primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.isFree
                            ? 'Free'
                            : '₺${e.price.toStringAsFixed(0)}',
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(category: e.category),
                      const SizedBox(height: 5),
                      Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              e.location,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${e.registeredCount}/${e.capacity}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            e.isFull ? 'Dolu' : '${e.spotsLeft} yer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: e.isFull
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ), // MouseRegion
    ); // GestureDetector
  }
}

// --- Category badge ---

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
