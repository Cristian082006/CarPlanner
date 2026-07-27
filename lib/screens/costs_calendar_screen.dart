import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../utils/calendar_events.dart';
import '../utils/costs.dart';
import '../utils/date_utils.dart';
import 'add_edit_reminder_screen.dart';
import 'vehicle_detail_screen.dart';

class CostsCalendarScreen extends StatefulWidget {
  const CostsCalendarScreen({super.key});

  @override
  State<CostsCalendarScreen> createState() => CostsCalendarScreenState();
}

class CostsCalendarScreenState extends State<CostsCalendarScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper.instance;
  late final TabController _tabController;

  List<CostEntry> _costEntries = [];
  List<CalendarEvent> _events = [];
  bool _loading = true;

  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final vehicles = await _db.getVehicles();
    final documents = await _db.getAllDocuments();
    final serviceRecords = await _db.getAllServiceRecords();
    final reminders = await _db.getReminders();
    final vehiclesById = {for (final v in vehicles) v.id: v};

    if (!mounted) return;
    setState(() {
      _costEntries = buildCostEntries(
        documents: documents,
        serviceRecords: serviceRecords,
        vehiclesById: vehiclesById,
      );
      _events = buildCalendarEvents(
        documents: documents,
        serviceRecords: serviceRecords,
        reminders: reminders,
        vehiclesById: vehiclesById,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.navCosts),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: S.costsTabLabel),
            Tab(text: S.calendarTabLabel),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CostsTab(entries: _costEntries),
                  _CalendarTab(
                    events: _events,
                    displayedMonth: _displayedMonth,
                    selectedDay: _selectedDay,
                    onMonthChanged: (m) => setState(() {
                      _displayedMonth = m;
                      _selectedDay = null;
                    }),
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                    onEventTap: _openEvent,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openEvent(CalendarEvent event) async {
    if (event.reminder != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditReminderScreen(reminder: event.reminder)),
      );
      _load();
    } else if (event.vehicleId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: event.vehicleId!)),
      );
      _load();
    }
  }
}

class _CostsTab extends StatelessWidget {
  final List<CostEntry> entries;

  const _CostsTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              S.noCostsRecorded,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
    final groups = groupCostsByVehicle(entries);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.totalCosts, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${total.toStringAsFixed(0)} ${S.costUnit}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final group in groups) _CostGroupTile(group: group),
      ],
    );
  }
}

class _CostGroupTile extends StatelessWidget {
  final CostGroup group;

  const _CostGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(group.label),
      subtitle: Text('${group.total.toStringAsFixed(0)} ${S.costUnit}'),
      children: group.entries
          .map((e) => ListTile(
                leading: Icon(e.icon),
                title: Text(e.title),
                subtitle: Text(formatDate(e.date)),
                trailing: Text('${e.amount.toStringAsFixed(0)} ${S.costUnit}'),
              ))
          .toList(),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  final List<CalendarEvent> events;
  final DateTime displayedMonth;
  final DateTime? selectedDay;
  final void Function(DateTime month) onMonthChanged;
  final void Function(DateTime day) onDaySelected;
  final void Function(CalendarEvent event) onEventTap;

  const _CalendarTab({
    required this.events,
    required this.displayedMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onEventTap,
  });

  Map<DateTime, List<CalendarEvent>> get _eventsByDay {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final eventsByDay = _eventsByDay;
    final firstOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7; // Luni = 0

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final selectedKey = selectedDay != null
        ? DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)
        : null;

    final dayEntries = selectedKey != null ? (eventsByDay[selectedKey] ?? []) : <CalendarEvent>[];
    final monthEventsCount = eventsByDay.entries
        .where((e) => e.key.year == displayedMonth.year && e.key.month == displayedMonth.month)
        .fold<int>(0, (sum, e) => sum + e.value.length);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(
                  DateTime(displayedMonth.year, displayedMonth.month - 1),
                ),
              ),
              Text(
                S.monthYearLabel(displayedMonth.month, displayedMonth.year),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                  DateTime(displayedMonth.year, displayedMonth.month + 1),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: S.weekdayShortLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ))
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = index - leadingBlanks + 1;
            final dayKey = DateTime(displayedMonth.year, displayedMonth.month, day);
            final dayEvents = eventsByDay[dayKey] ?? const <CalendarEvent>[];
            final isToday = dayKey == todayKey;
            final isSelected = dayKey == selectedKey;

            return GestureDetector(
              onTap: () => onDaySelected(dayKey),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isToday
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                        fontWeight: isToday || isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    if (dayEvents.isNotEmpty)
                      Wrap(
                        spacing: 2,
                        children: dayEvents
                            .take(3)
                            .map((e) => Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : e.color,
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 24),
        if (selectedKey == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              monthEventsCount == 0 ? S.noEventsThisMonth : S.selectDayHint,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else if (dayEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(S.noEventsThisDay, style: const TextStyle(color: Colors.grey)),
          )
        else
          ...dayEntries.map((e) => ListTile(
                leading: Icon(e.icon, color: e.color),
                title: Text(e.title),
                subtitle: Text(e.subtitle),
                onTap: () => onEventTap(e),
              )),
      ],
    );
  }
}
