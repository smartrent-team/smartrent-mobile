class TenantPaymentArgs {
  final String invoiceCode;
  final int amount;
  final String roomLabel;
  final String? qrPayload;
  final String? checkoutUrl;
  final String? accountNumber;
  final String? accountName;
  final String? bankBin;
  final String? transferDescription;

  const TenantPaymentArgs({
    required this.invoiceCode,
    required this.amount,
    required this.roomLabel,
    this.qrPayload,
    this.checkoutUrl,
    this.accountNumber,
    this.accountName,
    this.bankBin,
    this.transferDescription,
  });
}
