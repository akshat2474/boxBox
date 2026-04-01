import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../models/race_message.dart';
import '../../../../models/driver.dart';
import '../../../services/openf1_service.dart';

class SessionHubScreen extends ConsumerStatefulWidget {
  final int sessionKey;
  final String title;
  final String? sessionDateStart;

  const SessionHubScreen({
    super.key,
    required this.sessionKey,
    required this.title,
    this.sessionDateStart,
  });

  @override
  ConsumerState<SessionHubScreen> createState() => _SessionHubScreenState();
}

class _SessionHubScreenState extends ConsumerState<SessionHubScreen> {
  final Set<int> _expandedIndices = {};

  Color _flagColor(String? flag) {
    switch (flag?.toUpperCase()) {
      case 'RED': return const Color(0xFFFF3B30);
      case 'YELLOW':
      case 'DOUBLE YELLOW': return const Color(0xFFFFD60A);
      case 'GREEN': return const Color(0xFF30D158);
      case 'BLUE': return const Color(0xFF0A84FF);
      case 'CHEQUERED': return Colors.white;
      default: return AppTheme.textSecondary;
    }
  }

  Color _categoryColor(String category, String? flag) {
    if (category == 'Flag') return _flagColor(flag);
    switch (category.toLowerCase()) {
      case 'safetycar': return const Color(0xFFFFD60A);
      case 'drs': return const Color(0xFF30D158);
      case 'incident': return const Color(0xFFFF9F0A);
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFuture = widget.sessionDateStart != null &&
        (DateTime.tryParse(widget.sessionDateStart!)?.isAfter(DateTime.now()) ?? false);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            if (!isFuture)
              Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF30D158), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Race Control', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
          ],
        ),
      ),
      body: isFuture ? _buildFuture() : _buildFeed(),
    );
  }

  Widget _buildFuture() {
    final date = widget.sessionDateStart != null ? DateTime.tryParse(widget.sessionDateStart!)?.toLocal() : null;
    final formattedDate = date != null ? DateFormat('EEEE, MMMM d · HH:mm').format(date) : 'TBD';
    String countdown = '';
    if (date != null) {
      final diff = date.difference(DateTime.now());
      if (diff.inDays > 0) {
        countdown = '${diff.inDays}d ${diff.inHours.remainder(24)}h';
      } else if (diff.inHours > 0) countdown = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      else countdown = '${diff.inMinutes}m';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(36), border: Border.all(color: AppTheme.border)),
              child: const Icon(Icons.flag_outlined, color: AppTheme.textMuted, size: 32),
            ),
            const SizedBox(height: 24),
            Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
              child: Column(
                children: [
                  const Text('SESSION STARTS', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(formattedDate, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (countdown.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.f1Red.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.f1Red.withOpacity(0.4))),
                      child: Text(countdown, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.f1Red)),
                    ),
                    const SizedBox(height: 4),
                    const Text('away', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Race control data will appear here\nonce the session begins.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    final hubAsync = ref.watch(sessionHubProvider(widget.sessionKey));
    return hubAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.f1Red)),
      error: (err, _) => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      )),
      data: (hubData) {
        final messages = hubData.messages;
        final driversMap = hubData.driversMap;

        if (messages.isEmpty) {
          return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.radio_button_off, color: AppTheme.textMuted, size: 48),
              SizedBox(height: 16),
              Text('No race control data available.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          itemCount: messages.length,
          itemBuilder: (ctx, i) => _buildCard(messages[i], i, driversMap),
        );
      },
    );
  }

  Widget _buildCard(RaceMessage msg, int index, Map<int, Driver> driversMap) {
    final date = msg.date.toLocal();
    final time = DateFormat('HH:mm:ss').format(date);
    final isFlag = msg.category == 'Flag';
    final color = _categoryColor(msg.category, msg.flag);
    final driver = msg.driverNumber != null ? driversMap[msg.driverNumber] : null;
    final hasDetails = driver != null || msg.lapNumber != null || msg.sector != null || msg.scope != null;
    final isExpanded = _expandedIndices.contains(index);

    return GestureDetector(
      onTap: hasDetails ? () => setState(() {
        if (isExpanded) {
          _expandedIndices.remove(index);
        } else {
          _expandedIndices.add(index);
        }
      }) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.category.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isFlag ? FontWeight.w700 : FontWeight.w500,
                            color: isFlag ? color : Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasDetails)
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 18),
                ],
              ),
            ),
            if (isExpanded && hasDetails)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (driver != null) ...[
                      _detail(Icons.person_rounded, 'Driver', '#${driver.driverNumber} ${driver.fullName}',
                          Color(int.tryParse('FF${driver.teamColour}', radix: 16) ?? 0xFFFFFFFF)),
                      _detail(Icons.directions_car_rounded, 'Team', driver.teamName, null),
                    ],
                    if (msg.lapNumber != null) _detail(Icons.loop_rounded, 'Lap', 'Lap ${msg.lapNumber}', null),
                    if (msg.scope != null) _detail(Icons.track_changes_rounded, 'Scope', msg.scope!, null),
                    if (msg.sector != null) _detail(Icons.pie_chart_outline, 'Sector', 'Sector ${msg.sector}', null),
                    _detail(Icons.access_time_rounded, 'Timestamp', DateFormat('d MMM yyyy, HH:mm:ss').format(date), null),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 7),
          Text('$label  ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppTheme.textSecondary))),
        ],
      ),
    );
  }
}
