CREATE TABLE IF NOT EXISTS places (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    category VARCHAR(64) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO places (id, name, address, category, latitude, longitude)
VALUES
    ('poi-1', 'Springland Resort', 'Springland Resort Road, Pagadian City', 'Resort', 7.8242, 123.4350),
    ('poi-2', 'Four Queens Resort', 'Four Queens Road, Pagadian City', 'Resort', 7.8280, 123.4345),
    ('poi-3', 'N Hotel', 'N Hotel Blvd, Pagadian City', 'Hotel', 7.8320, 123.4360),
    ('poi-4', 'LEX Badminton Center', 'Sports Complex Road, Pagadian City', 'Sports', 7.8305, 123.4330),
    ('poi-5', 'Tuburan Central School', 'Tuburan, Pagadian City', 'School', 7.8290, 123.4300),
    ('poi-6', 'Pagadian Cemetery', 'Cemetery Road, Pagadian City', 'Cemetery', 7.8260, 123.4250),
    ('poi-7', 'Pagadian Doctors Hospital', 'Hospital Road, Pagadian City', 'Hospital', 7.8220, 123.4280),
    ('poi-8', 'Casa de Lolita', 'Lolita Street, Pagadian City', 'Restaurant', 7.8255, 123.4320),
    ('poi-9', 'Pagadian City Hall', 'Rizal Avenue, Pagadian City', 'Government', 7.8250, 123.4380)
ON CONFLICT (id) DO NOTHING;
