// import 'package:luftdaten.at/main.dart';
// import 'package:oauth2_client/oauth2_client.dart';
// import 'package:oauth2_client/oauth2_helper.dart';
//
// class LuftdatenDatahubOAuth2Helper {
//   void a() {
//     OAuth2Helper helper = getIt<OAuth2Helper>();
//     helper.getTokenFromStorage().then((value) => value!);
//   }
// }
//
// class LuftdatenDatahubOAuth2Client extends OAuth2Client {
//   LuftdatenDatahubOAuth2Client(): super(
//       authorizeUrl: 'https://datahub.luftdaten.at/api/o/authorize',
//       tokenUrl: 'https://datahub.luftdaten.at/api/o/token',
//       redirectUri: 'at.luftdaten.pmble://oauth2redirect',
//       customUriScheme: 'at.luftdaten.pmble',
//   );
// }