import 'package:flutter/widgets.dart';

import '../config/constants.dart';

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < AppConstants.mobileBreakpoint) return ScreenSize.mobile;
  if (width < AppConstants.tabletBreakpoint) return ScreenSize.tablet;
  return ScreenSize.desktop;
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => screenSizeOf(this);
  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;
  bool get isCompact => screenSize == ScreenSize.mobile;
}

/// Pick the right value for the current screen size.
T responsive<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  switch (screenSizeOf(context)) {
    case ScreenSize.mobile:
      return mobile;
    case ScreenSize.tablet:
      return tablet ?? mobile;
    case ScreenSize.desktop:
      return desktop ?? tablet ?? mobile;
  }
}
