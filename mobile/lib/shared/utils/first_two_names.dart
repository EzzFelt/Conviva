String firstTwoNames(String fullName) {
  return fullName.trim().split(RegExp(r'\s+')).take(2).join(' ');
}
