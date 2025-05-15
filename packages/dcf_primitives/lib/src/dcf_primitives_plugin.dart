import 'package:dcflight/dcflight.dart';


/// Plugin for DCFlight primitives
class DCFPrimitivesPlugin extends DCFPlugin {
  /// Singleton instance
  static final DCFPrimitivesPlugin instance = DCFPrimitivesPlugin._();
  
  /// Private constructor for singleton
  DCFPrimitivesPlugin._();
  
  @override
  String get name => 'dcf_primitives';
  
  @override
  int get priority => 10; // Higher priority than default (100)
  
  @override
  void registerComponents() {
  
}}