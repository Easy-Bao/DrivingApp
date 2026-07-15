export async function fetchPassengerName(passengerId: string): Promise<string> {
  if (!passengerId) return 'Passenger';
  try {
    const passengerServiceUrl = process.env.PASSENGER_SERVICE_URL;
    if (!passengerServiceUrl) {
      throw new Error("Configuration Error: PASSENGER_SERVICE_URL is required but not set.");
    }
    const response = await fetch(`${passengerServiceUrl}/passengers/${passengerId}`);
    if (response.ok) {
      const passenger = await response.json();
      return passenger?.name || 'Passenger';
    }
  } catch (err) {
    console.error('Failed to fetch passenger name from passenger-service:', err);
  }
  return 'Passenger';
}
