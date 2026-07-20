import { db } from '../../shared/drizzle.ts';
import { drivers, reviews } from '../../db/schema.ts';
import { eq, desc } from 'drizzle-orm';
import { Driver, Review, DriverRepository } from '../entities/driver.types.ts';
import { CreateDriverRequest } from '../schemas/driver.schema.ts';

export class DrizzleDriverRepository implements DriverRepository {
  async registerDriver(details: CreateDriverRequest): Promise<Driver> {
    const passwordHash = await Bun.password.hash(details.password, { algorithm: 'bcrypt', cost: 10 });
    const [created] = await db.insert(drivers)
      .values({
        id: crypto.randomUUID(),
        name: details.name,
        email: details.email,
        phone: details.phone,
        vehicleType: details.vehicleType,
        plateNumber: details.plateNumber,
        passwordHash,
      })
      .returning();
    return created;
  }

  async findDriverByEmail(email: string): Promise<Driver | null> {
    const [matched] = await db.select().from(drivers).where(eq(drivers.email, email));
    return matched || null;
  }

  async findDriverById(id: string): Promise<Driver | null> {
    const [matched] = await db.select().from(drivers).where(eq(drivers.id, id));
    return matched || null;
  }

  async findOnlineDrivers(): Promise<Driver[]> {
    return await db.select().from(drivers).where(eq(drivers.isOnline, true));
  }

  async updateOnlineStatus(id: string, isOnline: boolean, lat?: number, lng?: number): Promise<Driver> {
    const updateValues: any = { isOnline };
    if (lat !== undefined && lat !== null) updateValues.lat = lat;
    if (lng !== undefined && lng !== null) updateValues.lng = lng;

    const [updated] = await db.update(drivers)
      .set(updateValues)
      .where(eq(drivers.id, id))
      .returning();

    if (!updated) {
      throw new Error('Driver not found');
    }
    return updated;
  }

  async fetchDriverReviews(driverId: string, page = 1, limit = 5): Promise<Review[]> {
    const offset = (page - 1) * limit;
    return await db.select()
      .from(reviews)
      .where(eq(reviews.driverId, driverId))
      .orderBy(desc(reviews.createdAt))
      .limit(limit)
      .offset(offset);
  }

  async addDriverReview(review: Omit<Review, 'id' | 'createdAt'>): Promise<Review> {
    const [inserted] = await db.insert(reviews)
      .values({
        id: crypto.randomUUID(),
        driverId: review.driverId,
        passengerName: review.passengerName,
        rating: review.rating,
        comment: review.comment,
      })
      .returning();
    return inserted;
  }

  async updateDriverRating(driverId: string, rating: number): Promise<Driver> {
    const [updated] = await db.update(drivers)
      .set({ rating })
      .where(eq(drivers.id, driverId))
      .returning();
    if (!updated) {
      throw new Error('Driver not found');
    }
    return updated;
  }
}
