// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

final class Offset extends ffi.Struct {
  @ffi.Double()
  external double x;

  @ffi.Double()
  external double y;
}

final class BoundingBox extends ffi.Struct {
  external Offset top_left;

  external Offset top_right;

  external Offset bottom_left;

  external Offset bottom_right;
}
