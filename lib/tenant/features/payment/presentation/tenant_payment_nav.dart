import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tenant/features/billing/data/tenant_invoice_service.dart';
import 'package:smartrent_mobile/tenant/features/billing/domain/models/tenant_invoice.dart';
import 'package:smartrent_mobile/tenant/features/payment/domain/tenant_payment_args.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_qr_page.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_messages.dart';

final _invoiceService = TenantInvoiceService();

Future<void> openTenantPaymentQr(
  BuildContext context,
  TenantInvoice invoice,
) async {
  if (invoice.isPaid) {
    showTenantPaymentSnackBar(context, TenantPaymentMessages.alreadyPaid);
    return;
  }

  TenantInvoice current = invoice;

  if (!current.canPay) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(TenantPaymentMessages.loadingQr),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await _invoiceService.ensurePaymentLink(current.id);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (res.statusCode == 200 && res.data['success'] == true) {
        current = TenantInvoice.fromJson(
          res.data['invoice'] as Map<String, dynamic>,
        );
      } else {
        final err = TenantPaymentMessages.fromApi(res.data['error']?.toString());
        showTenantPaymentSnackBar(context, err);
        return;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        final msg = e is DioException
            ? TenantPaymentMessages.fromApi(
                (e.response?.data is Map)
                    ? (e.response!.data as Map)['error']?.toString()
                    : null,
              )
            : TenantPaymentMessages.unavailable;
        showTenantPaymentSnackBar(context, msg);
      }
      return;
    }
  }

  if (!current.hasLink || current.checkoutUrl == null || current.checkoutUrl!.trim().isEmpty) {
    if (!context.mounted) return;
    showTenantPaymentSnackBar(context, TenantPaymentMessages.noLinkAvailable);
    return;
  }

  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TenantPaymentQRPage(
        args: TenantPaymentArgs(
          invoiceId: current.id,
          invoiceCode: current.invoiceCode,
          amount: current.totalAmount.round(),
          roomLabel: current.roomLabel,
          qrPayload: current.qrPayload,
          checkoutUrl: current.checkoutUrl,
          accountNumber: current.paymentAccountNumber,
          accountName: current.paymentAccountName,
          bankBin: current.paymentBankBin,
          transferDescription: current.paymentDescription,
        ),
      ),
    ),
  );
}
