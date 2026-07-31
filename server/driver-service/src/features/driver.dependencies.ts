import { DriverRepositoryImpl } from './repositories/driver.repository.ts';
import { DriverOperationsRepository } from './repositories/driver_operations.repository.ts';
import { DriverService } from './services/driver.service.ts';
import { DriverOperationsService } from './services/driver_operations.service.ts';

export const driverRepository = new DriverRepositoryImpl();
export const driverOperationsRepository = new DriverOperationsRepository();
export const driverService = new DriverService(driverRepository);
export const driverOperationsService = new DriverOperationsService(
  driverOperationsRepository,
  driverRepository,
);
