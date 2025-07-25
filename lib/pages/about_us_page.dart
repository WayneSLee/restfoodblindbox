import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// 這是您需要在 App Store Connect 和 Google Play Console 中設定的「消耗性商品ID」。
const List<String> _kProductIds = <String>[
  'donation_small',
  'donation_medium',
  'donation_large',
];

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = <ProductDetails>[];
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // 處理錯誤
    });
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _isLoading = false;
      });
      return;
    }

    final ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _isLoading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 顯示處理中 UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handlePurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('贊助失敗: ${error.message}'),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    // 這裡可以加入您的後端驗證邏輯
    // 驗證成功後...
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('非常感謝您的支持！'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('關於我們 & 支持計畫'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '一個在理髮廳誕生的惜食夢想',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '我們的故事，從一張理髮椅開始。\n\n'
                  '我，冠冠，是一個有點胖的軟體工程師，也是小傑理髮廳超過十年的老顧客。我們總在剪髮時天南地北地聊。一次閒聊中，小傑提到了他在國外旅遊時，看到一款能媒合店家與顧客、解決剩食問題的 App，他覺得這個點子非常有意義。\n\n'
                  '「你看，這樣既能減少浪費，又能幫助像學生或小資族用更少的錢飽餐一頓，不是很好嗎？」\n\n這句話深深打動了我。從小，我的家訓就是「盤子裡的食物不能剩」，即使遇到討厭的菜，也一定會為了不浪費而吃完。這個想法，與我內心深處的信念不謀而合。\n\n當時的我雖然工作與案子纏身，但這個想法的種子已經埋下。當案子告一段落，我便毅然決然地投入開發。而我的室友，注重健康、白手起家的業務「和和」，因為小時候家境貧困，更能體會食物的珍貴。他聽了這個計畫後，也義不容辭地加入，希望能為社會盡一份心力。\n\n就這樣，一個工程師、一位業務、一位髮型設計師，三個志同道合的朋友，憑著一股熱情，開啟了「食物謎盒」的旅程。',
              style: TextStyle(fontSize: 16, height: 1.7),
            ),
            const Divider(height: 48),
            Text(
              '支持我們繼續前進',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '從一個想法到一個能運作的 App，我們投入了所有的下班時間與積蓄。然而，要讓這個夢想持續運轉，我們也面臨著現實的挑戰：伺服器的維護費用、地圖服務的開銷，以及需要投入更多時間心力去和店家溝通、推廣......這些都是我們目前遇到的困難。\n\n'
                  '如果您也認同「食物不該被浪費」的理念，希望能用一杯咖啡、一頓飯的金額，支持我們這個小團隊繼續走下去，讓這個有意義的平台得以存活、茁壯。',
              style: TextStyle(fontSize: 16, height: 1.7),
            ),
            const SizedBox(height: 24),
            _buildDonationOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationOptions() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isAvailable) {
      return const Center(child: Text('無法連接到商店，請稍後再試。'));
    }
    if (_products.isEmpty) {
      return const Center(
        child: Text('目前沒有可用的贊助選項。\n請確認您已在 App Store/Google Play 設定好商品。'),
      );
    }

    return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _products.map((product) {
    return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: ElevatedButton(
    onPressed: () {
    final PurchaseParam purchaseParam =
    PurchaseParam(productDetails: product);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    },
    child: Text('贊助 ${product.title} (${product.price})'),
    ),
    );
    }).toList(),
    );
  }
}