// Simple Web3 utility helpers (address detection, identicon & explorer URL)

String? extractEthAddress(String text) {
  final reg = RegExp(r'0x[a-fA-F0-9]{40}');
  final m = reg.firstMatch(text);
  return m?.group(0);
}

String identiconUrl(String address) {
  final seed = Uri.encodeComponent(address.toLowerCase());
  // Use DiceBear identicon PNG endpoint
  return 'https://avatars.dicebear.com/api/identicon/$seed.png';
}

String explorerUrl(String address) {
  // Etherscan for Ethereum addresses
  return 'https://etherscan.io/address/$address';
}
