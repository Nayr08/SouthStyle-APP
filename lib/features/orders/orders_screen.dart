import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/progress_order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Orders',
                  style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildFilterChip(context),
              ],
            ),
            const SizedBox(height: 16),
            const ProgressOrderCard(
              orderNumber: 'ORD-001',
              customerName: 'John Doe',
              status: 'In Progress',
              progress: 0.65,
            ),
            const SizedBox(height: 8),
            const ProgressOrderCard(
              orderNumber: 'ORD-002',
              customerName: 'Jane Smith',
              status: 'Pending',
              progress: 0.2,
            ),
            const SizedBox(height: 8),
            const ProgressOrderCard(
              orderNumber: 'ORD-003',
              customerName: 'Mike Johnson',
              status: 'Completed',
              progress: 1.0,
            ),
            const SizedBox(height: 8),
            const ProgressOrderCard(
              orderNumber: 'ORD-004',
              customerName: 'Sarah Williams',
              status: 'In Progress',
              progress: 0.45,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.createOrderRoute);
        },
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Filter',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
