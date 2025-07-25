import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/store_model.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isOpen = store.isOpen;
    final Color statusColor =
    isOpen ? Colors.green.shade700 : Colors.grey.shade600;
    final String statusText = isOpen ? '營業中' : '休息中';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  store.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.store, size: 100),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // --- vvv 這是本次修改的核心 vvv ---
                  // 我們讓 Chip 直接使用 ChipTheme 的設定，不再寫死顏色
                  if (store.tags.isNotEmpty)
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 2.0,
                      children: store.tags
                          .map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                          .toList(),
                    )
                  else
                    Text('暫無標籤', style: TextStyle(color: Colors.grey[600])),
                  // --- ^^^ 修改到此結束 ^^^ ---

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(store.rating.toString()),
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