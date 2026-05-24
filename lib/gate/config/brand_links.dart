import '../../core/mask_util.dart';

const List<int> _privacyMask = [7, 88, 223, 60, 88, 102, 35, 160, 124, 160, 92, 228, 236, 90, 1, 233, 110, 130, 243, 186, 177, 13, 130, 215, 5, 124, 1, 105, 183, 220, 26, 2, 64, 45, 211, 171, 176, 200, 242, 220, 143, 68, 113, 208, 193, 38, 37, 88];
const List<int> _supportMask = [7, 88, 223, 60, 88, 102, 35, 160, 124, 160, 92, 228, 236, 90, 1, 233, 110, 130, 243, 186, 177, 13, 130, 215, 5, 124, 1, 105, 183, 223, 29, 27, 70, 35, 194, 166, 179, 208, 233, 221, 138];

String get brandPrivacyPageUrl => unmask(_privacyMask);
String get brandSupportPageUrl  => unmask(_supportMask);
