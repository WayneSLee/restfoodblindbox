import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 1. 引入 flutter_bloc
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart'; // 2. 引入 CartBloc
import 'package:restfoodblindbox/bloc/cart/cart_event.dart'; // 3. 引入 CartEvent
import 'package:restfoodblindbox/models/product_model.dart';
import 'package:restfoodblindbox/pages/product_detail.dart';
import 'package:restfoodblindbox/widgets/login_prompt_dialog.dart';

// 貨幣格式化工具
final formatter =
NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);

class ProductCard extends StatelessWidget {
  final Product product;
  final String storeId;

  const ProductCard({
    super.key,
    required this.product,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image,
                        size: 100, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatter.format(product.price),
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          if (FirebaseAuth.instance.currentUser == null) {
                            // 如果是 null (訪客)，就顯示提示登入的對話框
                            showLoginPromptDialog(context);
                          } else {
                            // 如果不是 null (已登入)，才執行原本的加入購物車邏輯
                            context
                                .read<CartBloc>()
                                .add(CartItemAdded(product, storeId));

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已加入購物車！'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
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
    );
  }
}