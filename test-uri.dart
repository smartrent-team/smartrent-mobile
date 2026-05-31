void main() {
  var url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=295000000&vnp_Command=pay&vnp_CreateDate=20260531195042&vnp_CurrCode=VND&vnp_IpAddr=127.0.0.1&vnp_Locale=vn&vnp_OrderInfo=ThanhToan_INV-202605-0001&vnp_OrderType=other&vnp_ReturnUrl=http%3A%2F%2Flocalhost%3A3000%2Fapi%2Fwebhooks%2Fvnpay%2Freturn&vnp_TmnCode=TU6GNW0A&vnp_TxnRef=INV-202605-0001_1780230108319&vnp_Version=2.1.0&vnp_SecureHash=1cce1db39a8124d371f6eace6da5a6401734e6075870b44444f377176f90622dbd2e0d5ab12afff16e5eaba4e987ae8756c5def79262cb73c1637dcae042b752";
  var parsed = Uri.parse(url);
  print(parsed.toString());
  print(parsed.toString() == url);
}
