import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tenant/features/billing/domain/models/tenant_invoice.dart';
import 'package:smartrent_mobile/tenant/features/payment/domain/tenant_payment_args.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/pages/payment_qr_page.dart';

void openTenantPaymentQr(BuildContext context, TenantInvoice invoice) {
  if (!invoice.canPay) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hóa đơn này chưa có mã QR thanh toán hoặc đã được thanh toán.'),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TenantPaymentQRPage(
        args: TenantPaymentArgs(
          invoiceCode: invoice.invoiceCode,
          amount: invoice.totalAmount.round(),
          roomLabel: invoice.roomLabel,
          qrPayload: invoice.qrPayload,
          checkoutUrl: invoice.checkoutUrl,
          accountNumber: invoice.paymentAccountNumber,
          accountName: invoice.paymentAccountName,
          bankBin: invoice.paymentBankBin,
          transferDescription: invoice.paymentDescription,
        ),
      ),
    ),
  );
}
