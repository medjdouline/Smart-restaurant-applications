// lib/core/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/api/api_service.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/order_repository_impl.dart';
import '../blocs/orders/order_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  ApiService.initialize();

  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(apiClient: ApiService.client),
  );

  getIt.registerFactory<OrderBloc>(
    () => OrderBloc(orderRepository: getIt<OrderRepository>()),
  );
}

List<BlocProvider> getGlobalBlocProviders() {
  return [
    BlocProvider<OrderBloc>(
      create: (context) => getIt<OrderBloc>(),
    ),
  ];
}

List<RepositoryProvider> getGlobalRepositoryProviders() {
  return [];
}