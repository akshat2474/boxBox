import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../models/session.dart';
import '../../../services/openf1_service.dart';

class _Meeting {
  final int meetingKey;
  final String circuitShortName;
  final String countryName;
  final String location;
  final List<Session> sessions;

  _Meeting({
    required this.meetingKey,
    required this.circuitShortName,
    required this.countryName,
    required this.location,
    required this.sessions,
  });

  DateTime get firstDate => DateTime.tryParse(sessions.first.dateStart) ?? DateTime.now();
  DateTime get lastDate => DateTime.tryParse(sessions.last.dateEnd) ?? DateTime.now();

  bool get isCompleted => lastDate.isBefore(DateTime.now());
  bool get isUpcoming => firstDate.isAfter(DateTime.now());
  bool get isLive => !isCompleted && !isUpcoming;
}

List<_Meeting> _groupByMeeting(List<Session> sessions) {
  final map = <int, List<Session>>{};
  for (final s in sessions) {
    map.putIfAbsent(s.meetingKey, () => []).add(s);
  }
  return map.entries.map((e) {
    final sorted = e.value..sort((a, b) => a.dateStart.compareTo(b.dateStart));
    final first = sorted.first;
    return _Meeting(
      meetingKey: e.key,
      circuitShortName: first.circuitShortName,
      countryName: first.countryName,
      location: first.location,
      sessions: sorted,
    );
  }).toList()
    ..sort((a, b) => a.firstDate.compareTo(b.firstDate));
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _upcomingExpanded = false;

  void _openHub(BuildContext context, Session session) {
    context.push('/hub/${session.sessionKey}', extra: {
      'title': '${session.sessionName} · ${session.circuitShortName}',
      'dateStart': session.dateStart,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(currentSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.f1Red)),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
        data: (sessions) {
          final allSorted = sessions.toList()
            ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

          final meetings = _groupByMeeting(allSorted);
          final latestMeeting = meetings.lastWhere((m) => m.isCompleted, orElse: () => meetings.first);
          final pastMeetings = meetings.where((m) => m.isCompleted && m.meetingKey != latestMeeting.meetingKey).toList().reversed.toList();
          final upcomingMeetings = meetings.where((m) => m.isUpcoming || m.isLive).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // ── Latest Race Weekend ─────────────────
              _sectionLabel('Latest Race Weekend', Icons.emoji_events_rounded, AppTheme.f1Red),
              _MeetingCard(meeting: latestMeeting, onSessionTap: (s) => _openHub(context, s), highlight: true),
              const SizedBox(height: 28),

              // ── Upcoming (collapsible) ─────────────
              if (upcomingMeetings.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() => _upcomingExpanded = !_upcomingExpanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: Color(0xFF30D158), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming  •  ${upcomingMeetings.length} races',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _upcomingExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _upcomingExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Column(
                    children: upcomingMeetings.map((m) => _MeetingCard(
                      meeting: m,
                      onSessionTap: (s) => _openHub(context, s),
                      highlight: false,
                    )).toList(),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
              ],

              // ── Past Weekends ──────────────────────
              if (pastMeetings.isNotEmpty) ...[
                _sectionLabel('Past Weekends', Icons.history_rounded, AppTheme.textSecondary),
                ...pastMeetings.map((m) => _MeetingCard(
                  meeting: m,
                  onSessionTap: (s) => _openHub(context, s),
                  highlight: false,
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final _Meeting meeting;
  final void Function(Session) onSessionTap;
  final bool highlight;

  const _MeetingCard({required this.meeting, required this.onSessionTap, required this.highlight});

  Color _sessionColor(String type) {
    switch (type.toLowerCase()) {
      case 'race': return AppTheme.f1Red;
      case 'qualifying': return const Color(0xFFFFD60A);
      case 'practice': return const Color(0xFF0A84FF);
      case 'sprint': return const Color(0xFFBF5AF2);
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = '${DateFormat('MMM d').format(meeting.firstDate)} – ${DateFormat('MMM d').format(meeting.lastDate)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppTheme.f1Red.withOpacity(0.5) : AppTheme.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            meeting.circuitShortName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          if (meeting.isLive) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 1.2)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${meeting.location}, ${meeting.countryName}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Text(dateRange, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Session rows
          ...meeting.sessions.map((session) {
            final sDate = DateTime.tryParse(session.dateStart)?.toLocal();
            final isSessionPast = DateTime.tryParse(session.dateEnd)?.isBefore(DateTime.now()) ?? false;
            final color = _sessionColor(session.sessionType);

            return GestureDetector(
              onTap: () => onSessionTap(session),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSessionPast ? color.withOpacity(0.25) : color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.sessionName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSessionPast ? AppTheme.textSecondary : Colors.white,
                            ),
                          ),
                          if (sDate != null)
                            Text(
                              DateFormat('EEE, MMM d · HH:mm').format(sDate),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (isSessionPast)
                      const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.textMuted)
                    else
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.6)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
