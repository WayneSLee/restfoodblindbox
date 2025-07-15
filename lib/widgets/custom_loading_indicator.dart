import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double? size;

  const CustomLoadingIndicator({super.key, this.size = 150.0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        // 使用 Lottie.asset 來讀取您放在 assets/animations/ 資料夾中的動畫檔案
        // 請確保底下的路徑，與您實際的檔案名稱和位置相符
        child: Lottie.asset(
          'assets/animations/loading_animation.json',
          // 您也可以在這裡調整動畫的其他屬性，例如 fit: BoxFit.contain
        ),
      ),
    );
  }
}