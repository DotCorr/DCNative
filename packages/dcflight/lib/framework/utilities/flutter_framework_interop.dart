import 'package:flutter/widgets.dart';

export 'package:flutter/material.dart' hide runApp;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
void runWidgetApp(Widget widget)=>runApp(widget);