import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:telegram_lite/services/auth_service.dart';
import 'package:telegram_lite/services/mock_data.dart';

class PaymentService {
  final TelegramDataService dataService;
  final AuthService authService;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  Function()? onPurchaseSuccess;

  PaymentService({required this.dataService, required this.authService});

  static const String _premiumProductId = 'telegram_premium_subscription';

  void initialize() {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle error here.
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<void> buyPremium(BuildContext context) async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store is not available at the moment.')),
        );
      }
      return;
    }

    const Set<String> kIds = <String>{_premiumProductId};
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      // For development, if product is not found, we can mock the purchase
      // so you can test the UI without setting up Google Play Console yet.
      _mockPurchaseFlow(context);
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // Using buyNonConsumable for a subscription
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Valid purchase
          _grantPremiumAccess();
        }
        if (purchaseDetails.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _grantPremiumAccess() {
    dataService.setPremium(true);
    authService.updatePremiumStatus(true);
    if (onPurchaseSuccess != null) {
      onPurchaseSuccess!();
    }
  }

  // A mock flow so that you can test the UI immediately without store setup
  void _mockPurchaseFlow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mocking payment (Product not found in store)'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      _grantPremiumAccess();
    });
  }
}
