import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as gsi_web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

Widget buildGoogleSignInButton() {
  return (GoogleSignInPlatform.instance as gsi_web.GoogleSignInPlugin)
      .renderButton(
        configuration: gsi_web.GSIButtonConfiguration(
          theme: gsi_web.GSIButtonTheme.filledBlack,
          shape: gsi_web.GSIButtonShape.rectangular,
          size: gsi_web.GSIButtonSize.large,
          type: gsi_web.GSIButtonType.standard,
          logoAlignment: gsi_web.GSIButtonLogoAlignment.center,
        ),
      );
}
