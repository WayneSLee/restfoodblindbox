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
                  if (store.tags.isNotEmpty)
                    Wrap(
                      spacing: 4.0, // 縮小水平間距
                      runSpacing: 2.0, // 縮小垂直間距
                      children: store.tags
                          .map((tag) => Chip(
                        label: Text(tag),
                        // 移除固定的文字顏色，讓它自動適應主題
                        labelStyle: const TextStyle(
                          fontSize: 11, // 縮小字體
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0), // 縮小內邊距
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 縮小點擊範圍
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                            )),
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