import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../models/trading_models.dart';
import '../providers/trading_provider.dart';

class OrderPlacementBottomSheet extends StatefulWidget {
  const OrderPlacementBottomSheet({
    super.key,
    required this.security,
    this.initialSide = 'buy',
    this.userAvailableShares = 0,
  });

  final TradableSecurity security;
  final String initialSide;
  final int userAvailableShares;

  static Future<void> show(
    BuildContext context, {
    required TradableSecurity security,
    String initialSide = 'buy',
    int userAvailableShares = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrderPlacementBottomSheet(
        security: security,
        initialSide: initialSide,
        userAvailableShares: userAvailableShares,
      ),
    );
  }

  @override
  State<OrderPlacementBottomSheet> createState() =>
      _OrderPlacementBottomSheetState();
}

class _OrderPlacementBottomSheetState extends State<OrderPlacementBottomSheet> {
  late String _side;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _qtyController = TextEditingController(text: '10');
    _priceController = TextEditingController(
      text: widget.security.referencePriceEtb.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_qtyController.text) ?? 0;
  double get _priceEtb => double.tryParse(_priceController.text) ?? 0.0;
  double get _totalEtb => _quantity * _priceEtb;
  int get _priceMinor => (_priceEtb * 100).round();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final tradingProvider = context.watch<TradingProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final availableCashEtb = walletProvider.summary?.available.etb ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.security.symbol,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.security.companyName,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Side selector (Buy / Sell toggle)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _side = 'buy'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _side == 'buy'
                            ? AppColors.secondaryEmerald
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'BUY SHARES',
                        style: TextStyle(
                          color: _side == 'buy'
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _side = 'sell'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _side == 'sell'
                            ? AppColors.error
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SELL SHARES',
                        style: TextStyle(
                          color: _side == 'sell'
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Balance / holdings indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _side == 'buy'
                      ? 'Available Cash Balance'
                      : 'Available Shares to Sell',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
                Text(
                  _side == 'buy'
                      ? '${availableCashEtb.toStringAsFixed(2)} ETB'
                      : '${widget.userAvailableShares} shares',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _side == 'buy'
                        ? AppColors.secondaryEmerald
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quantity Field
          Text('Quantity (Shares)', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final cur = _quantity;
                  if (cur > 1) {
                    _qtyController.text = (cur - 1).toString();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final cur = _quantity;
                  _qtyController.text = (cur + 1).toString();
                  setState(() {});
                },
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price Field
          Text('Limit Price per Share (ETB)', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: 'ETB',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              helperText:
                  'Ref price: ${widget.security.referencePriceEtb.toStringAsFixed(2)} ETB',
            ),
          ),
          const SizedBox(height: 16),

          // Total order value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total Value',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Text(
                '${_totalEtb.toStringAsFixed(2)} ETB',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (_localError != null || tradingProvider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localError ?? tradingProvider.errorMessage!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _side == 'buy'
                    ? AppColors.secondaryEmerald
                    : AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: tradingProvider.isSubmitting ? null : _submitOrder,
              child: tradingProvider.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _side == 'buy' ? 'CONFIRM BUY ORDER' : 'CONFIRM SELL ORDER',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    setState(() => _localError = null);

    if (_quantity <= 0) {
      setState(() => _localError = 'Quantity must be at least 1 share');
      return;
    }
    if (_priceEtb <= 0) {
      setState(() => _localError = 'Price must be greater than 0');
      return;
    }

    if (_side == 'sell' && _quantity > widget.userAvailableShares) {
      setState(() => _localError =
          'You only have ${widget.userAvailableShares} shares available to sell');
      return;
    }

    final provider = context.read<TradingProvider>();
    final result = await provider.placeOrder(
      ipoId: widget.security.ipoId,
      side: _side,
      quantity: _quantity,
      pricePerShareMinor: _priceMinor,
    );

    if (mounted && result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.executions.isNotEmpty
                ? 'Order matched and executed immediately!'
                : 'Limit order placed successfully on market.',
          ),
          backgroundColor: AppColors.secondaryEmerald,
        ),
      );
    }
  }
}
