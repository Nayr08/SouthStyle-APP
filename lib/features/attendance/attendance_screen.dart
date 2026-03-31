import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/attendance.dart';
import '../../core/models/employee.dart';
import 'attendance_provider.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => context.read<AttendanceProvider>().refresh(),
        child: const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: SizedBox(height: 6)),
            SliverToBoxAdapter(child: _FilterChips()),
            SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _SummaryCards()),
            SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _WorkerListHeader()),
            SliverToBoxAdapter(child: SizedBox(height: 8)),
            _WorkerList(),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AttendanceProvider>();
    final from = DateFormat('MMM d').format(ap.range.from);
    final to = DateFormat('MMM d, y').format(ap.range.to);
    final subtitle =
        ap.preset == DatePreset.today ? 'Today, $to' : '$from — $to';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips ──────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AttendanceProvider>();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, 'Today', DatePreset.today, ap),
          _chip(context, 'This Week', DatePreset.thisWeek, ap),
          _chip(context, '15 Days', DatePreset.fifteenDays, ap),
          _chip(context, 'This Month', DatePreset.thisMonth, ap),
          _customChip(context, ap),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    DatePreset preset,
    AttendanceProvider ap,
  ) {
    final selected = ap.preset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ap.selectPreset(preset),
        selectedColor: AppColors.gold,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: selected
              ? AppColors.gold
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _customChip(BuildContext context, AttendanceProvider ap) {
    final selected = ap.preset == DatePreset.custom;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          Icons.date_range,
          size: 16,
          color: selected ? Colors.white : AppColors.gold,
        ),
        label: Text(selected
            ? '${DateFormat('M/d').format(ap.range.from)} – ${DateFormat('M/d').format(ap.range.to)}'
            : 'Custom'),
        onPressed: () => _pickRange(context, ap),
        backgroundColor:
            selected ? AppColors.gold : Theme.of(context).colorScheme.surface,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
        side: BorderSide(
          color: selected
              ? AppColors.gold
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, AttendanceProvider ap) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: ap.range.from,
        end: ap.range.to,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.gold,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ap.selectCustomRange(picked.start, picked.end);
    }
  }
}

// ─── Summary cards (Present / Absent / Late) ───────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AttendanceProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'Present',
              value: ap.isLoading ? '—' : '${ap.totalPresent}',
              color: AppColors.success,
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              label: 'Absent',
              value: ap.isLoading ? '—' : '${ap.totalAbsent}',
              color: AppColors.error,
              icon: Icons.cancel_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              label: 'Late',
              value: ap.isLoading ? '—' : '${ap.totalLate}',
              color: AppColors.gold,
              icon: Icons.schedule,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Worker list header ────────────────────────────────

class _WorkerListHeader extends StatelessWidget {
  const _WorkerListHeader();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AttendanceProvider>().workers.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Workers ($count)',
        style: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─── Worker list ───────────────────────────────────────

class _WorkerList extends StatelessWidget {
  const _WorkerList();

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AttendanceProvider>();

    if (ap.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }

    if (ap.workers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No employees found.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final w = ap.workers[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _WorkerCard(summary: w),
          );
        },
        childCount: ap.workers.length,
      ),
    );
  }
}

// ─── Worker card ───────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final WorkerAttendanceSummary summary;
  const _WorkerCard({required this.summary});

  Color _dotColor() {
    if (summary.records.isEmpty) return AppColors.error;
    final latest = summary.records.first.status;
    switch (latest) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late_:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = summary.employee;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBreakdown(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Colored status dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _dotColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emp.role.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.daysWorked} days worked',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _BreakdownSheet(
          summary: summary,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// ─── Bottom sheet: daily breakdown + salary ─────────────

class _BreakdownSheet extends StatelessWidget {
  final WorkerAttendanceSummary summary;
  final ScrollController scrollController;

  const _BreakdownSheet({
    required this.summary,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final emp = summary.employee;
    final currencyFmt = NumberFormat('#,##0.00');

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Name + role
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      emp.role.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // Quick stat badges
              _badge('P', '${summary.daysPresent}', AppColors.success),
              const SizedBox(width: 6),
              _badge('A', '${summary.daysAbsent}', AppColors.error),
              const SizedBox(width: 6),
              _badge('L', '${summary.daysLate}', AppColors.gold),
            ],
          ),
        ),
        const Divider(height: 20),

        // Salary summary box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salary Estimate',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.daysWorked} days x ${currencyFmt.format(emp.dailyRate)} = ${currencyFmt.format(summary.salary)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Daily Breakdown',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Day-by-day list
        Expanded(
          child: summary.records.isEmpty
              ? Center(
                  child: Text(
                    'No attendance records in this range.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: summary.records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = summary.records[i];
                    return _DayRow(record: r);
                  },
                ),
        ),
      ],
    );
  }

  Widget _badge(String letter, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            letter,
            style: GoogleFonts.dmSans(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Single day row in breakdown ───────────────────────

class _DayRow extends StatelessWidget {
  final Attendance record;
  const _DayRow({required this.record});

  Color _color() {
    switch (record.status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late_:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat('h:mm a');
    final timeIn =
        record.timeIn != null ? timeFmt.format(record.timeIn!) : '—';
    final timeOut =
        record.timeOut != null ? timeFmt.format(record.timeOut!) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _color(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(record.date),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'In: $timeIn  •  Out: $timeOut',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _color().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.status.label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _color(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
