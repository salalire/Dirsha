import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/dirsha_button.dart';
import '../../ipos/models/ipo_models.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';

/// Bottom sheet dialog for reviewing terms and submitting an IPO subscription.
class SubscriptionBottomSheet extends StatefulWidget {
  const SubscriptionBottomSheet({super.key, required this.ipo});

  final IpoDetail ipo;

  static Future<SubscriptionModel?> show(
    BuildContext context, {
    required IpoDetail ipo,
  }) {
    return showModalBottomSheet<SubscriptionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SubscriptionBottomSheet(ipo: ipo),
    );
  }

  @override
  State<SubscriptionBottomSheet> createState() =>
      _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends State<SubscriptionBottomSheet> {
  late final TextEditingController _quantityController;
  late int _quantity;
  bool _termsAccepted = false;
  late final String _idempotencyKey;

  int get _priceMinor => widget.ipo.pricePerShare.santim;
  int get _minShares {
    if (widget.ipo.minInvestment != null && _priceMinor > 0) {
      return (widget.ipo.minInvestment!.santim / _priceMinor).ceil();
    }
    return 1;
  }

  int? get _maxShares {
    if (widget.ipo.maxInvestment != null && _priceMinor > 0) {
      return (widget.ipo.maxInvestment!.santim / _priceMinor).floor();
    }
    return null;
  }

  int get _totalAmountMinor => _quantity * _priceMinor;
  Money get _totalMoney => Money(_totalAmountMinor);

  @override
  void initState() {
    super.initState();
    _quantity = _minShares > 0 ? _minShares : 1;
    _quantityController = TextEditingController(text: _quantity.toString());
    _idempotencyKey = _generateUuidV4();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  void _updateQuantity(int newQty) {
    if (newQty < 1) return;
    setState(() {
      _quantity = newQty;
      _quantityController.text = newQty.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    final wallet = walletProvider.summary;
    final available = wallet?.available ?? Money.zero;

    final hasSufficientFunds = available >= _totalMoney;
    final isWithinMin = _quantity >= _minShares;
    final isWithinMax = _maxShares == null || _quantity <= _maxShares!;
    final isValidQuantity = isWithinMin && isWithinMax;

    final canSubmit = hasSufficientFunds &&
        isValidQuantity &&
        _termsAccepted &&
        !subscriptionProvider.isSubmitting;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscribe: ${widget.ipo.title}',
                        style: AppTextStyles.cardTitleOf(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.ipo.companyName,
                        style: AppTextStyles.bodySmallOf(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(height: 24, color: AppColors.borderOf(context)),

            // Share price and constraints summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(
                    label: 'Price / Share',
                    value: Formatters.money(widget.ipo.pricePerShare),
                  ),
                  _InfoItem(
                    label: 'Min Shares',
                    value: _minShares.toString(),
                  ),
                  if (_maxShares != null)
                    _InfoItem(
                      label: 'Max Shares',
                      value: _maxShares.toString(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quantity selector
            Text('Number of Shares', style: AppTextStyles.labelSmallOf(context)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: _quantity > _minShares
                      ? () => _updateQuantity(_quantity - 1)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.financialLargeOf(context),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _quantity = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: (_maxShares == null || _quantity < _maxShares!)
                      ? () => _updateQuantity(_quantity + 1)
                      : null,
                ),
              ],
            ),
            if (!isWithinMin) ...[
              const SizedBox(height: 6),
              Text(
                'Minimum subscription is $_minShares shares',
                style: AppTextStyles.labelSmallOf(context).copyWith(color: AppColors.errorOf(context)),
              ),
            ] else if (!isWithinMax) ...[
              const SizedBox(height: 6),
              Text(
                'Maximum subscription is $_maxShares shares',
                style: AppTextStyles.labelSmallOf(context).copyWith(color: AppColors.errorOf(context)),
              ),
            ],
            const SizedBox(height: 16),

            // Financial breakdown card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasSufficientFunds
                      ? AppColors.borderOf(context)
                      : AppColors.errorOf(context).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _BreakdownRow(
                    label: 'Required Reservation',
                    value: Formatters.money(_totalMoney),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _BreakdownRow(
                    label: 'Available in Wallet',
                    value: Formatters.money(available),
                  ),
                  Divider(height: 16, color: AppColors.borderOf(context)),
                  _BreakdownRow(
                    label: 'Remaining Balance',
                    value: hasSufficientFunds
                        ? Formatters.money(
                            Money(available.santim - _totalAmountMinor))
                        : '0.00 ETB',
                    isDim: !hasSufficientFunds,
                  ),
                ],
              ),
            ),

            if (!hasSufficientFunds) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSurfaceOf(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.errorOf(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.errorOf(context), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient funds. You need ${Formatters.money(Money(_totalAmountMinor - available.santim))} more in available funds.',
                        style: AppTextStyles.bodySmallOf(context)
                            .copyWith(color: AppColors.errorOf(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Terms acknowledgement checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _termsAccepted,
              activeColor: AppColors.brandEmerald,
              title: Text(
                'I confirm my subscription request and authorize the immediate reservation of ${Formatters.money(_totalMoney)} from my available balance.',
                style: AppTextStyles.labelSmallOf(context).copyWith(color: AppColors.textPrimaryOf(context)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => setState(() => _termsAccepted = val ?? false),
            ),

            if (subscriptionProvider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subscriptionProvider.errorMessage!,
                style: AppTextStyles.bodySmallOf(context).copyWith(color: AppColors.errorOf(context)),
              ),
            ],

            const SizedBox(height: 20),

            // Action Button
            DirshaButton(
              label: 'Confirm Subscription',
              isLoading: subscriptionProvider.isSubmitting,
              isEnabled: canSubmit,
              onPressed: _handleConfirm,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirm IPO Subscription',
      message:
          'You are subscribing for $_quantity shares of ${widget.ipo.title} at ${Formatters.money(widget.ipo.pricePerShare)}/share.\n\nTotal reservation: ${Formatters.money(_totalMoney)}.\n\nReserved funds cannot be withdrawn or spent until allocation.',
      confirmLabel: 'Reserve Funds',
      cancelLabel: 'Cancel',
    );

    if (confirmed != true || !mounted) return;

    final subProvider = context.read<SubscriptionProvider>();
    final walletProvider = context.read<WalletProvider>();

    final result = await subProvider.submitSubscription(
      ipoId: widget.ipo.id,
      quantity: _quantity,
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;

    if (result != null) {
      await walletProvider.refresh();

      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop(result);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 48),
            title: const Text('Subscription Reserved'),
            content: Text(
              'Successfully submitted subscription for $_quantity shares of ${widget.ipo.title}!\n\n${Formatters.money(_totalMoney)} has been reserved in your wallet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.labelSmallOf(context)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.financialMediumOf(context)),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDim = false,
  });

  final String label;
  final String value;
  final bool isBold;
  final bool isDim;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))
              : AppTextStyles.bodySmallOf(context),
        ),
        Text(
          value,
          style: isBold
              ? AppTextStyles.financialMediumOf(context)
              : (isDim
                  ? AppTextStyles.bodySmallOf(context)
                  : AppTextStyles.financialSmallOf(context)),
        ),
      ],
    );
  }
}
