import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/job_order.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/progress_order_card.dart';
import 'orders_provider.dart';
import 'order_details_modal.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrdersProvider(),
      child: Scaffold(
        body: const _OrdersScreenContent(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.createOrderRoute);
          },
          backgroundColor: AppColors.gold,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _OrdersScreenContent extends StatelessWidget {
  const _OrdersScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();

    return Column(
      children: [
        // Header with filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Orders',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              _buildFilterDropdown(context, provider),
            ],
          ),
        ),
        // Active filter display
        if (provider.selectedFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filtering by: ${_statusLabel(provider.selectedFilter!)}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Orders list
        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : provider.orders.isEmpty
                  ? Center(
                      child: Text(
                        'No orders found',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.orders.length,
                      itemBuilder: (context, index) {
                        final order = provider.orders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ProgressOrderCard(
                            orderNumber: order.formattedOrderId,
                            customerName: order.customerName,
                            status: _statusLabel(order.status),
                            progress: _statusProgress(order.status),
                            onTap: () => _showOrderDetails(context, order),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
      BuildContext context, OrdersProvider provider) {
    return PopupMenuButton<OrderStatus?>(
      onSelected: (value) {
        if (value == null) {
          provider.clearFilter();
        } else {
          provider.setFilter(value);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<OrderStatus?>(
          value: null,
          child: Text('All Orders'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<OrderStatus>(
          value: OrderStatus.pending,
          child: Text('Pending'),
        ),
        const PopupMenuItem<OrderStatus>(
          value: OrderStatus.cutting,
          child: Text('Cutting'),
        ),
        const PopupMenuItem<OrderStatus>(
          value: OrderStatus.printing,
          child: Text('Printing'),
        ),
        const PopupMenuItem<OrderStatus>(
          value: OrderStatus.done,
          child: Text('Completed'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Filter',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, JobOrder order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsModal(order: order),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cutting:
        return 'Cutting';
      case OrderStatus.printing:
        return 'Printing';
      case OrderStatus.done:
        return 'Completed';
    }
  }

  double _statusProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.2;
      case OrderStatus.cutting:
        return 0.45;
      case OrderStatus.printing:
        return 0.75;
      case OrderStatus.done:
        return 1.0;
    }
  }
}
