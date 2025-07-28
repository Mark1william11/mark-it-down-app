// lib/core/providers/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  // We can configure Dio here with base URLs, interceptors, etc.
  return Dio(BaseOptions(baseUrl: "https://jsonplaceholder.typicode.com/"));
}