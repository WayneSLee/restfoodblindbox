import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_event.dart';
import 'package:restfoodblindbox/models/product_model.dart';
import 'package:restfoodblindbox/pages/product_detail.dart';

// 貨幣格式化工具
final formatter =
NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);

class ProductListItem extends StatelessWidget {
  final Product product;
  final String storeId;

  const ProductListItem({
    super.key,
    required this.product,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = product.quantity <= 0;
    // --- vvv 這是本次新增的邏輯 vvv ---
    final bool hasPickupTime = product.pickupStartTime != null &&
        product.pickupEndTime != null &&
        product.pickupStartTime!.isNotEmpty &&
        product.pickupEndTime!.isNotEmpty;
    // --- ^^^ 新增到此結束 ^^^ ---

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: product,
                storeId: storeId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  product.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // --- vvv 這是本次新增的 UI vvv ---
                    if (hasPickupTime)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.pickupStartTime} - ${product.pickupEndTime} 可自取',
                              style: TextStyle(
                                  color: Colors.grey[800], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    // --- ^^^ 新增到此結束 ^^^ ---
                    const SizedBox(height: 4),
                    Text(
                      isSoldOut ? '已售完' : '剩餘: ${product.quantity}',
                      style: TextStyle(
                        color: isSoldOut ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(product.price),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: isSoldOut ? null : () {
                            context
                                .read<CartBloc>()
                                .add(CartItemAdded(product, storeId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已加入購物車！'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: '加入購物車',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}