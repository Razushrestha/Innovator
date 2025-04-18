import 'dart:developer';
import 'package:googleapis_auth/auth_io.dart';

class NotificationAccessToken {
  static String? _token;
  static DateTime? _expiry;

  static Future<String?> get getToken async {
    // Check if token exists and is not expired
    if (_token != null &&
        _expiry != null &&
        DateTime.now().isBefore(_expiry!)) {
      return _token;
    }
    // Fetch a new token if no valid token is available
    return await _getAccessToken();
  }

  static Future<String?> _getAccessToken() async {
    try {
      const fMessagingScope =
          'https://www.googleapis.com/auth/firebase.messaging';

      final client = await clientViaServiceAccount(
          ServiceAccountCredentials.fromJson({
            "type": "service_account",
            "project_id": "message-ea92f",
            "private_key_id": "35ccf636db4bf2d2ab7c267a869bf9e20b9d2b4a",
            "private_key":
                "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDpRehV32InkKZ3\nbLORWw/ez0ntY5oS4c3BaN9WYm4zbxlPEcW6TUTrZcch5TbEEMlq1H1jSFiObIqf\nnjix1aYvBF7qOPivQckdeIUuzxIqOmlcLvlhW34+iKeIYfRaDAQk4AkrS0qYRwDv\nu0bfOqqAsaMSNhvgiVbYxFXppY6/t4lpp2aZXKVnZik0nn5DdnCyv4ngeoNgq9UP\nzfs7x3SKP6RWnRJKhvPfH5hW8E+DV47+tvlkKHrY9TB1zEUzxCMNiLhmuhUDJix/\nfNX27ZOPCSuc6NxN9mFlgxnzYHjp4sD/tI4pE1AJklSO9yhXNK7NHNqrRhfx/4Dn\nYsunxFCpAgMBAAECggEALVb7G4W5jDsfP+MO29e5M/NSSSOs1LKyzT7W+fFTvgeA\nAdBQgC94j9BObhYhGOayX2NBo8RyAeyy3Odh2Z7PGCBfWmMMYvQEZQgByuFQhIip\n5dLzgarI1Nq2xVlUpxPi0lABODsAGqziT7Y0xjqe3Tipm2aM8I2BJcyzbiBRqI1i\nxvMPYaeyk4rW+0VEJ8jruNj3tnElQzaeuGvQBK2b2yWeECAMeWy66eleF7HiPm+p\nddc+siGfU/WysO5nowRmOE1N+H/8Fsi8mad5oykFjGeeZLZZPDN6PWusFA1PFrOZ\nbaR403eboRya4PDv7E0e3IUY+bguOnLjqlIaCP76qQKBgQD9cIkGYgTwoTUbtqaC\nmw65ApaO5MBsIuU6ANHT0z6hkmT631DcTm11mjsmGgIRCdC0Mr27iL/XHUQmgndo\naB5x+vqEkUJSggD/O+1pFDPrbwPB9fUIClB9m10HOsN2e1RSjBSXuLBjbpT4ZiFf\n8wgvMafgwU1NFAc+Cy3EOuLaZwKBgQDroTdUgVHAr+Ux3bUcUKN07ezrE/y9UY3P\n2nrhBH9T0TKLH8qmvdBVBDak8T6YLs6GHdYFMfEH8mqGOEiXeKT7x8NBBYqjsyvH\n9yYMkP8EvsRIAKbwEWPr5BN5GkIvz7u6b1N2ddgcJCtiE8baafDdyme43M4RCMt7\nY8nc4JSybwKBgAGgyHCPDqMRFgtAiB9MqbKMjrUKSSYorzpJKQ/oSn21OArYhmdz\n5YYc4IZlImBDpOCTdt6OiVTzbi2lJuk3ygJHb3aMjFWFWkZJd0P2ikLX6rlDQDi2\nAEBeUCGswfav4iHJnpQ+7nslCbXyygIYyJOtCPwLodh96XH/lmKtUim/AoGALTnl\nZ9fmfCiGwlp+n6+uoAvm1Hwin6feo02ZFkWJtunJXMC+YeC+8wJ7Bo+zZvxc8Ysa\ngCbEz7Ss05RMAp7Kc/U0ue85XBBQz/HVIMZX3G5NOFC/ugZsemNthWoP2CN0MeWa\nTHtz/nrGxO1s1pFNBRULcYUYHFbmz4kovrdwcwsCgYB3uACWjU4T192V8B71P6Fm\nDQRFTvdy0BqfhCTfPghHelemLQ2Phtc1PwcGnTb/oj1mcbT768E2we2FyguvB/yA\nMsVfPvjeCXoBRDRY61OxNSo3DcSCa4YQKwsUJcL8Jaw8net0YXbVvWr9cRu+5YfS\nMUU0Zbk8stB/VkGY3Yw2lQ==\n-----END PRIVATE KEY-----\n",
            "client_email":
                "firebase-adminsdk-e0go3@message-ea92f.iam.gserviceaccount.com",
            "client_id": "109877043757931329614",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url":
                "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url":
                "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-e0go3%40message-ea92f.iam.gserviceaccount.com",
            "universe_domain": "googleapis.com"
          }),
          [fMessagingScope]);
      _token = client.credentials.accessToken.data;
      _expiry = client.credentials.accessToken.expiry;

      return _token;
    } catch (e) {
      log('$e');
      return null;
    }
  }
}
