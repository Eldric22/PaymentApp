import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';
import 'dart:convert';

class StripeService {

  static const Map<String, String> _testTokens = {
    '4242424242424242' : 'tok_visa',
    '4000000034576934' : 'tok_visa_debit',
    '5555555555554444' : 'tok_mastercard',
    '5200828282828210' : 'tok_mastercard_debit',
    '4000000000000001' : 'tok_chargeDeclined',
    '4000000000009995' : 'tok_chargeDeclinedInsufficientFunds',

  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,

  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return {
        'success': false,
        'error': 'unknown test card. use 4242424242424242 (success)',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),

        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },

        body: {
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_data[type]' : 'card',
          'payment_method_data[card][token]' : token,
          'confirm': 'true',
          'automatic_payment_methods[enabled]': 'true',
          'automatic_payment_methods[allow_redirects]': 'never',
        },
      );

      final data =jsonDecode(response.body);

      if (response.statusCode == 200 && (data['status'] == 'succeeded' || data['status'] == 'requires_action' || data['status'] == 'requires_confirmation')) {
        return {
          'success' : true,
          'id' : data['id'],
          'amount': data['amount'] / 100,
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'error': data['error']?['message'] ?? 'Payment failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
