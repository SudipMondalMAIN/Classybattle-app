import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_method_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/payment_method_service.dart';

/// The user's saved UPI/bank withdrawal destinations. Empty (not
/// error) when signed out.
final paymentMethodsProvider = FutureProvider<List<PaymentMethodModel>>((ref) async {
  try {
    return await paymentMethodService.fetchMethods();
  } on UnauthenticatedException {
    return [];
  }
});
