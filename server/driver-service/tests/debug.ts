/// Debug script to trace driver-service signup errors.
import app from '../src/index.ts';

const res = await app.fetch(
  new Request('http://localhost/drivers/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Test Driver',
      email: 'debug@test.com',
      phone: '09111111111',
      vehicleType: 'Bao Bao',
      plateNumber: 'XYZ 9999',
      password: 'driverpass123',
    }),
  })
);

console.log('Status:', res.status);
console.log('Response:', await res.text());
