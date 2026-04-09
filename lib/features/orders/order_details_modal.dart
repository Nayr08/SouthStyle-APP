import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/job_order.dart';
import '../../core/theme/app_colors.dart';

class OrderDetailsModal extends StatelessWidget {
  final JobOrder order;

  const OrderDetailsModal({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, 'Order ID', order.formattedOrderId),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Customer', order.customerName),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Product Type',
                    _productTypeLabel(order.productType),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Quantity', '${order.quantity} units'),
                  const SizedBox(height: 12),
                  _buildStatusBadge(context, order.status),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Created By',
                    order.createdBy,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Created At',
                    DateFormat('MMM d, yyyy hh:mm a').format(order.createdAt),
                  ),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.notes!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            'Status',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
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

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.cutting:
        return AppColors.info;
      case OrderStatus.printing:
        return AppColors.gold;
      case OrderStatus.done:
        return AppColors.success;
    }
  }

  String _productTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.tshirt:
        return 'T-Shirt';
      case ProductType.tarpaulin:
        return 'Tarpaulin';
      case ProductType.sticker:
        return 'Sticker';
      case ProductType.mug:
        return 'Mug';
      case ProductType.other:
        return 'Other';
    }
  }
}
