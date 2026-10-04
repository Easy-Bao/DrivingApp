CREATE TABLE ride_reports (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    reporter_id integer NOT NULL,
    reported_user_id integer NOT NULL,
    reporter_role text NOT NULL,
    category text NOT NULL,
    severity text NOT NULL,
    description text NOT NULL,
    status text NOT NULL DEFAULT 'submitted',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ride_reports_reporter_role_check CHECK (
        reporter_role IN ('driver', 'passenger')
    ),
    CONSTRAINT ride_reports_category_check CHECK (
        category IN (
            'accident', 'driver_identity_mismatch', 'fare_dispute',
            'fraud', 'harassment', 'no_show', 'non_payment',
            'prohibited_cargo', 'property_damage', 'route_issue',
            'threat_or_violence', 'unsafe_driving', 'vehicle_mismatch',
            'other'
        )
    ),
    CONSTRAINT ride_reports_severity_check CHECK (
        severity IN ('standard', 'high', 'critical')
    ),
    CONSTRAINT ride_reports_status_check CHECK (
        status IN ('submitted', 'under_review', 'resolved', 'dismissed')
    ),
    CONSTRAINT ride_reports_description_length_check CHECK (
        char_length(description) BETWEEN 1 AND 2000
    ),
    CONSTRAINT ride_reports_participants_differ_check CHECK (
        reporter_id <> reported_user_id
    )
);

CREATE UNIQUE INDEX ride_reports_reporter_ride_category
    ON ride_reports (ride_id, reporter_id, category);

CREATE INDEX ride_reports_status_created_at
    ON ride_reports (status, created_at);

CREATE INDEX ride_reports_reported_user_created_at
    ON ride_reports (reported_user_id, created_at);
