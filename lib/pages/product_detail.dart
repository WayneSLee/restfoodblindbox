import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_event.dart';
import 'package:restfoodblindbox/models/product_model.dart';
import 'package:restfoodblindbox/widgets/login_prompt_dialog.dart';

final formatter =
NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final String storeId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.storeId,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  double get _totalPrice => widget.product.price * _quantity;

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = widget.product.quantity <= 0;
    // --- vvv 這是本次新增的邏輯 vvv ---
    final bool hasPickupTime = widget.product.pickupStartTime != null &&
        widget.product.pickupEndTime != null &&
        widget.product.pickupStartTime!.isNotEmpty &&
        widget.product.pickupEndTime!.isNotEmpty;
    // --- ^^^ 新增到此結束 ^^^ ---

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.product.imageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Icon(Icons.storefront,
                            size: 100, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(widget.product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(formatter.format(widget.product.price),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.grey[800])),
                const SizedBox(height: 16),
                Text(widget.product.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 24),
                // --- vvv 這是本次新增的 UI vvv ---
                if (hasPickupTime)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule,
                            size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          '自取時段: ${widget.product.pickupStartTime} - ${widget.product.pickupEndTime}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                // --- ^^^ 新增到此結束 ^^^ ---
                Text(
                  isSoldOut ? '已售完' : '僅剩 ${widget.product.quantity} 件',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSoldOut ? Colors.red : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 20)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed:
                      !isSoldOut && _quantity < widget.product.quantity
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              child: ElevatedButton.icon(
                onPressed: isSoldOut
                    ? null
                    : () {
                  // 3. 同樣檢查使用者是否已登入
                  if (FirebaseAuth.instance.currentUser == null) {
                    showLoginPromptDialog(context);
                  } else {
                    // 已登入才執行加入購物車邏輯
                    context.read<CartBloc>().add(CartItemAdded(
                        widget.product, widget.storeId,
                        quantity: _quantity));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('已加入購物車'),
                          duration: Duration(seconds: 1)),
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSoldOut ? Colors.grey : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(isSoldOut ? '已售完' : '加入 $_quantity 項到購物車'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}