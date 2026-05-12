// Platform-aware entry point
// This file automatically exports the correct implementation

// For mobile (Android/iOS)
export 'fcm_service_mobile.dart'
// For web
if (dart.library.html) 'fcm_service_web.dart';