import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/job_order.dart';
import '../../core/models/employee.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_input.dart';

// ─── Row model for the dynamic items table ─────────────

class _ItemRow {
  final TextEditingController name;
  final TextEditingController size;
  final TextEditingController quantity;
  final UniqueKey key;

  _ItemRow()
      : name = TextEditingController(),
        size = TextEditingController(),
        quantity = TextEditingController(),
        key = UniqueKey();

  void dispose() {
    name.dispose();
    size.dispose();
    quantity.dispose();
  }
}

// ─── Default checklists per product type ───────────────

const Map<ProductType, List<String>> _defaultChecklist = {
  ProductType.tshirt: [
    'Design confirmed',
    'Sizes confirmed',
    'Material ready',
    'Printing done',
    'QC passed',
  ],
  ProductType.tarpaulin: [
    'Design confirmed',
    'Dimensions confirmed',
    'Material ready',
    'Printing done',
    'Finishing done',
    'QC passed',
  ],
  ProductType.sticker: [
    'Design confirmed',
    'Material selected',
    'Cutting template ready',
    'Printing done',
    'QC passed',
  ],
  ProductType.mug: [
    'Design confirmed',
    'Mug stock available',
    'Sublimation done',
    'QC passed',
  ],
  ProductType.other: [
    'Requirements confirmed',
    'Material ready',
    'Production done',
    'QC passed',
  ],
};

// ─── Screen ────────────────────────────────────────────

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  ProductType _productType = ProductType.tshirt;
  final List<_ItemRow> _items = [_ItemRow()];
  late List<bool> _checklist;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checklist = List.filled(_defaultChecklist[_productType]!.length, false);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  void _onProductTypeChanged(ProductType type) {
    setState(() {
      _productType = type;
      _checklist = List.filled(_defaultChecklist[type]!.length, false);
    });
  }

  void _addItemRow() {
    setState(() => _items.add(_ItemRow()));
  }

  void _removeItemRow(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one item row has a name
    final hasValidItem =
        _items.any((r) => r.name.text.trim().isNotEmpty);
    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one order item.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    // Role guard
    if (auth.role != EmployeeRole.dataEntry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Data Entry staff can create orders.'),
        ),
      );
      return;
    }

    final employeeUuid = auth.employeeUuid;
    if (employeeUuid == null) return;

    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;

      // Build checklist notes
      final checklistLabels = _defaultChecklist[_productType]!;
      final checklistText = StringBuffer();
      for (var i = 0; i < checklistLabels.length; i++) {
        final mark = _checklist[i] ? 'x' : ' ';
        checklistText.writeln('[$mark] ${checklistLabels[i]}');
      }

      final userNotes = _notesController.text.trim();
      final combinedNotes = userNotes.isNotEmpty
          ? '$userNotes\n\n--- Checklist ---\n$checklistText'
          : '--- Checklist ---\n$checklistText';

      // 1. Insert job_order
      final orderData = await client
          .from('job_orders')
          .insert({
            'customer_name': _customerController.text.trim(),
            'product_type': _productType.toDbValue(),
            'quantity': int.parse(_quantityController.text.trim()),
            'notes': combinedNotes,
            'status': OrderStatus.pending.toDbValue(),
            'created_by': employeeUuid,
          })
          .select('id')
          .single();

      final orderId = orderData['id'] as String;

      // 2. Insert order_items
      final itemRows = _items
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => {
                'job_order_id': orderId,
                'name': r.name.text.trim(),
                'size': r.size.text.trim().isNotEmpty
                    ? r.size.text.trim()
                    : null,
                'quantity': int.tryParse(r.quantity.text.trim()) ?? 1,
              })
          .toList();

      if (itemRows.isNotEmpty) {
        await client.from('order_items').insert(itemRows);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Order',
          style: GoogleFonts.syne(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Customer name ──────────────
                  CustomInput(
                    label: 'Customer Name',
                    hint: 'Enter customer name',
                    controller: _customerController,
                    prefixIcon: Icons.person_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Product type chips ─────────
                  Text(
                    'Product Type',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProductType.values.map((t) {
                      final selected = t == _productType;
                      return ChoiceChip(
                        label: Text(t.label),
                        selected: selected,
                        onSelected: (_) => _onProductTypeChanged(t),
                        selectedColor: AppColors.gold,
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : onSurface,
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.surface,
                        side: BorderSide(
                          color: selected
                              ? AppColors.gold
                              : onSurface.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Quantity ────────────────────
                  CustomInput(
                    label: 'Total Quantity',
                    hint: 'Enter total pieces',
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.tag,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Notes ──────────────────────
                  CustomInput(
                    label: 'Notes (optional)',
                    hint: 'Additional instructions...',
                    controller: _notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ── Order items table ──────────
                  _SectionHeader(
                    title: 'Order Items',
                    trailing: TextButton.icon(
                      onPressed: _addItemRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Add Row',
                        style: GoogleFonts.dmSans(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ItemsTable(
                    items: _items,
                    onRemove: _removeItemRow,
                  ),
                  const SizedBox(height: 24),

                  // ── Checklist ──────────────────
                  _SectionHeader(title: 'Checklist — ${_productType.label}'),
                  const SizedBox(height: 8),
                  _Checklist(
                    labels: _defaultChecklist[_productType]!,
                    values: _checklist,
                    onChanged: (index, value) {
                      setState(() => _checklist[index] = value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Submit ─────────────────────
                  CustomButton(
                    label: 'Submit Order',
                    onPressed: _submit,
                    isLoading: _isSubmitting,
                    icon: Icons.check,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Dynamic items table ───────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<_ItemRow> items;
  final ValueChanged<int> onRemove;

  const _ItemsTable({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                _headerCell('Name', flex: 3),
                _headerCell('Size', flex: 2),
                _headerCell('Qty', flex: 1),
                const SizedBox(width: 36),
              ],
            ),
          ),
          // Data rows
          ...List.generate(items.length, (i) {
            final row = items[i];
            return Container(
              key: row.key,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _cellInput(context, row.name, 'Item name'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _cellInput(context, row.size, 'Size'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: _cellInput(
                      context,
                      row.quantity,
                      '#',
                      isNumber: true,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: items.length > 1
                        ? IconButton(
                            onPressed: () => onRemove(i),
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _cellInput(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.35),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
  }
}

// ─── Checklist ─────────────────────────────────────────

class _Checklist extends StatelessWidget {
  final List<String> labels;
  final List<bool> values;
  final void Function(int index, bool value) onChanged;

  const _Checklist({
    required this.labels,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: List.generate(labels.length, (i) {
          return Container(
            decoration: i > 0
                ? BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  )
                : null,
            child: CheckboxListTile(
              value: values[i],
              onChanged: (v) => onChanged(i, v ?? false),
              title: Text(
                labels[i],
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  decoration:
                      values[i] ? TextDecoration.lineThrough : null,
                ),
              ),
              activeColor: AppColors.gold,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          );
        }),
      ),
    );
  }
}
