import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../models/session.dart';
import '../../../services/openf1_service.dart';
import '../../../services/standings_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(currentSessionsProvider);
    final standingsAsync = ref.watch(currentStandingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bg,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: AppTheme.f1Red, shape: BoxShape.circle),
                  child: const Icon(Icons.sports_motorsports, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('BOX BOX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: sessionsAsync.when(
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: AppTheme.f1Red))),
              error: (e, _) => const SizedBox.shrink(),
              data: (sessions) {
                final now = DateTime.now();
                final sorted = sessions.where((s) => DateTime.tryParse(s.dateStart) != null).toList()
                  ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

                final upcoming = sorted.where((s) => DateTime.parse(s.dateStart).isAfter(now)).toList();
                final past = sorted.where((s) => DateTime.parse(s.dateEnd).isBefore(now)).toList();

                final nextSession = upcoming.isNotEmpty ? upcoming.first : null;
                final latestSession = past.isNotEmpty ? past.last : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Next race hero
                    if (nextSession != null) _NextRaceHero(session: nextSession, context: context),

                    // Upcoming sessions horizontal strip
                    if (upcoming.length > 1) ...[
                      _SectionHeader(
                        title: 'Coming Up',
                        onViewAll: () => context.go('/schedule'),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: upcoming.take(8).length,
                          itemBuilder: (ctx, i) {
                            final s = upcoming[i];
                            final date = DateTime.parse(s.dateStart).toLocal();
                            return GestureDetector(
                              onTap: () => context.push('/hub/${s.sessionKey}', extra: {
                                'title': '${s.sessionName} · ${s.circuitShortName}',
                                'dateStart': s.dateStart,
                              }),
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12, bottom: 4),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.sessionName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(s.circuitShortName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    Text(DateFormat('MMM d, HH:mm').format(date), style: const TextStyle(fontSize: 11, color: AppTheme.f1Red, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Latest race
                    if (latestSession != null) ...[
                      _SectionHeader(title: 'Last Race', onViewAll: () => context.push('/hub/${latestSession.sessionKey}', extra: {
                        'title': '${latestSession.sessionName} · ${latestSession.circuitShortName}',
                        'dateStart': latestSession.dateStart,
                      })),
                      GestureDetector(
                        onTap: () => context.push('/hub/${latestSession.sessionKey}', extra: {
                          'title': '${latestSession.sessionName} · ${latestSession.circuitShortName}',
                          'dateStart': latestSession.dateStart,
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                decoration: const BoxDecoration(
                                  color: AppTheme.f1Red,
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppTheme.f1Red, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(latestSession.sessionName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text('${latestSession.circuitShortName} · ${latestSession.countryName}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Standings
          SliverToBoxAdapter(
            child: standingsAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppTheme.f1Red))),
              error: (e, _) => const SizedBox.shrink(),
              data: (standings) {
                final top5 = standings.take(5).toList();
                return Column(
                  children: [
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Driver Standings',
                      onViewAll: () => context.push('/standings'),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < top5.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${top5[i].position}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: i == 0 ? AppTheme.f1Red : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${top5[i].givenName} ${top5[i].familyName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                        Text(top5[i].constructorName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text('${top5[i].points}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const SizedBox(width: 4),
                                  const Text('PTS', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (i < top5.length - 1)
                              const Divider(height: 1, color: AppTheme.border, indent: 16, endIndent: 16),
                          ],
                          InkWell(
                            onTap: () => context.push('/standings'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppTheme.border)),
                              ),
                              child: const Center(
                                child: Text('View Full Standings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.f1Red)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRaceHero extends StatelessWidget {
  final Session session;
  final BuildContext context;

  const _NextRaceHero({required this.session, required this.context});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(session.dateStart).toLocal();
    final diff = date.difference(DateTime.now());
    String countdown;
    if (diff.inDays > 0) {
      countdown = '${diff.inDays}D ${diff.inHours.remainder(24)}H';
    } else if (diff.inHours > 0) {
      countdown = '${diff.inHours}H ${diff.inMinutes.remainder(60)}M';
    } else {
      countdown = '${diff.inMinutes}M away';
    }

    return GestureDetector(
      onTap: () => context.push('/hub/${session.sessionKey}', extra: {
        'title': '${session.sessionName} · ${session.circuitShortName}',
        'dateStart': session.dateStart,
      }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red header bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.f1Red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Text('NEXT SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionName.toUpperCase(),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${session.circuitShortName} · ${session.countryName}',
                          style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('EEE, d MMM · HH:mm').format(date),
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(countdown, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.f1Red)),
                      const Text('AWAY', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: onViewAll,
            child: const Text('View all', style: TextStyle(fontSize: 14, color: AppTheme.f1Red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
