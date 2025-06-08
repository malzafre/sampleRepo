# Sample Data Structure Examples for NAGA VENTURE

This document provides examples of data structures for key tables in the NAGA VENTURE database schema. These examples illustrate how data should be formatted and related across tables.

## User Profiles

```json
// Example profile record
{
  "id": "550e8400-e29b-41d4-a716-446655440000", // UUID from auth.users
  "email": "john.doe@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+639171234567",
  "profile_image_url": "https://example.com/storage/profile-images/john_doe.jpg",
  "role": "business_owner",
  "is_verified": true,
  "created_at": "2025-06-01T08:30:00Z",
  "updated_at": "2025-06-01T08:30:00Z"
}
```

## Business Listing

```json
// Example business record
{
  "id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "business_name": "Naga Heritage Hotel",
  "business_type": "accommodation",
  "description": "Naga Heritage Hotel offers a blend of modern comfort and traditional Filipino hospitality in the heart of Naga City. Our rooms are designed to provide a relaxing atmosphere for both business and leisure travelers. With our central location, guests can easily access the city's major attractions, shopping centers, and business districts. Our friendly staff is dedicated to ensuring your stay is comfortable and memorable.",
  "address": "123 Magsaysay Avenue",
  "city": "Naga City",
  "province": "Camarines Sur",
  "postal_code": "4400",
  "phone": "+639187654321",
  "email": "info@nagaheritagehotel.com",
  "website": "https://www.nagaheritagehotel.com",
  "facebook_url": "https://facebook.com/nagaheritagehotel",
  "instagram_url": "https://instagram.com/nagaheritagehotel",
  "location": "SRID=4326;POINT(123.7511 13.6192)",
  "google_maps_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "status": "approved",
  "is_claimed": true,
  "is_featured": true,
  "average_rating": 4.50,
  "review_count": 28,
  "created_at": "2025-05-15T10:00:00Z",
  "updated_at": "2025-05-20T14:30:00Z",
  "approved_at": "2025-05-18T09:15:00Z",
  "approved_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}
```

## Categories

```json
// Example main category
{
  "id": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6",
  "name": "Food & Beverage",
  "description": "Restaurants, cafes, and other food establishments",
  "icon_url": "https://example.com/storage/icons/food_beverage.png",
  "is_active": true,
  "display_order": 1,
  "created_at": "2025-05-01T00:00:00Z",
  "updated_at": "2025-05-01T00:00:00Z",
  "created_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}

// Example sub-category
{
  "id": "b2c3d4e5-f6g7-h8i9-j0k1-l2m3n4o5p6q7",
  "main_category_id": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6",
  "name": "Cafe",
  "description": "Coffee shops and cafes",
  "icon_url": "https://example.com/storage/icons/cafe.png",
  "is_active": true,
  "display_order": 2,
  "created_at": "2025-05-01T00:00:00Z",
  "updated_at": "2025-05-01T00:00:00Z",
  "created_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}
```

## Room Types (for Accommodations)

```json
// Example room type
{
  "id": "c3d4e5f6-g7h8-i9j0-k1l2-m3n4o5p6q7r8",
  "business_id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "name": "Deluxe Double Room",
  "description": "Spacious room with one double bed, private bathroom, air conditioning, and city view.",
  "capacity": 2,
  "price_per_night": 2500.00,
  "quantity": 10,
  "is_available": true,
  "created_at": "2025-05-15T10:30:00Z",
  "updated_at": "2025-05-15T10:30:00Z"
}
```

## Tourist Spot

```json
// Example tourist spot
{
  "id": "d4e5f6g7-h8i9-j0k1-l2m3-n4o5p6q7r8s9",
  "name": "Peñafrancia Basilica",
  "description": "The Peñafrancia Basilica is a prominent Catholic church in Naga City, Camarines Sur, Philippines. It is home to the image of Our Lady of Peñafrancia, the patroness of the Bicol Region. The basilica is a significant pilgrimage site and the center of the annual Peñafrancia Festival, one of the largest Marian celebrations in Asia.",
  "spot_type": "religious",
  "address": "Peñafrancia Avenue",
  "city": "Naga City",
  "province": "Camarines Sur",
  "location": "SRID=4326;POINT(123.7583 13.6211)",
  "google_maps_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY5",
  "contact_phone": "+6354871234",
  "contact_email": "info@penafranciabasilica.org",
  "website": "https://www.penafranciabasilica.org",
  "opening_time": "06:00:00",
  "closing_time": "18:00:00",
  "entry_fee": 0.00,
  "status": "active",
  "is_featured": true,
  "average_rating": 4.80,
  "review_count": 45,
  "created_at": "2025-05-10T09:00:00Z",
  "updated_at": "2025-05-10T09:00:00Z",
  "created_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}
```

## Event

```json
// Example event
{
  "id": "e5f6g7h8-i9j0-k1l2-m3n4-o5p6q7r8s9t0",
  "name": "Peñafrancia Festival 2025",
  "description": "The Peñafrancia Festival is an annual religious festival held in honor of Our Lady of Peñafrancia, the patroness of the Bicol Region. The festival includes a novena, fluvial procession along the Naga River, and various cultural activities.",
  "start_date": "2025-09-12",
  "end_date": "2025-09-21",
  "start_time": "08:00:00",
  "end_time": "22:00:00",
  "venue_name": "Naga City Center",
  "address": "City Center, Naga City",
  "city": "Naga City",
  "province": "Camarines Sur",
  "location": "SRID=4326;POINT(123.7550 13.6200)",
  "tourist_spot_id": "d4e5f6g7-h8i9-j0k1-l2m3-n4o5p6q7r8s9",
  "entry_fee": 0.00,
  "organizer_name": "Naga City Government",
  "organizer_contact": "+6354871000",
  "organizer_email": "events@nagacity.gov.ph",
  "website": "https://www.penafrancia.net",
  "status": "upcoming",
  "is_featured": true,
  "created_at": "2025-06-01T11:00:00Z",
  "updated_at": "2025-06-01T11:00:00Z",
  "created_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}
```

## Booking

```json
// Example booking
{
  "id": "f6g7h8i9-j0k1-l2m3-n4o5-p6q7r8s9t0u1",
  "booking_number": "BK-20250610-1234",
  "guest_id": "550e8400-e29b-41d4-a716-446655440000",
  "business_id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "room_type_id": "c3d4e5f6-g7h8-i9j0-k1l2-m3n4o5p6q7r8",
  "check_in_date": "2025-07-15",
  "check_out_date": "2025-07-18",
  "number_of_guests": 2,
  "special_requests": "Room on a high floor with city view if possible.",
  "total_amount": 7500.00,
  "status": "confirmed",
  "payment_status": "paid",
  "payment_method": "gcash",
  "payment_reference": "GC12345678",
  "created_at": "2025-06-10T14:30:00Z",
  "updated_at": "2025-06-10T14:35:00Z"
}
```

## Review

```json
// Example review
{
  "id": "g7h8i9j0-k1l2-m3n4-o5p6-q7r8s9t0u1v2",
  "reviewer_id": "550e8400-e29b-41d4-a716-446655440000",
  "review_type": "business",
  "business_id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "tourist_spot_id": null,
  "event_id": null,
  "rating": 5,
  "comment": "Excellent service and very comfortable rooms. The staff was friendly and helpful. The location is perfect for exploring Naga City. Will definitely stay here again on my next visit.",
  "is_approved": true,
  "created_at": "2025-07-19T10:00:00Z",
  "updated_at": "2025-07-19T10:05:00Z"
}
```

## Promotion

```json
// Example promotion
{
  "id": "h8i9j0k1-l2m3-n4o5-p6q7-r8s9t0u1v2w3",
  "title": "Summer Special: 20% Off All Rooms",
  "description": "Book any room at Naga Heritage Hotel during June and July 2025 and get 20% off the regular rate. Use promo code SUMMER2025 when booking.",
  "start_date": "2025-06-01",
  "end_date": "2025-07-31",
  "business_id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "is_platform_wide": false,
  "discount_percentage": 20,
  "discount_amount": null,
  "promo_code": "SUMMER2025",
  "terms_conditions": "Valid for bookings made between June 1 and July 31, 2025. Subject to availability. Cannot be combined with other offers.",
  "status": "active",
  "created_at": "2025-05-25T09:00:00Z",
  "updated_at": "2025-05-25T09:00:00Z",
  "created_by": "550e8400-e29b-41d4-a716-446655440000"
}
```

## API Integration

```json
// Example API integration
{
  "id": "i9j0k1l2-m3n4-o5p6-q7r8-s9t0u1v2w3x4",
  "name": "google_maps",
  "api_key": "AIza...[redacted]",
  "api_secret": null,
  "config": {
    "api_key": "AIza...[redacted]",
    "region": "PH",
    "language": "en"
  },
  "is_active": true,
  "created_at": "2025-05-01T00:00:00Z",
  "updated_at": "2025-05-01T00:00:00Z",
  "created_by": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"
}
```

## Content Approval Request

```json
// Example content approval request
{
  "id": "j0k1l2m3-n4o5-p6q7-r8s9-t0u1v2w3x4y5",
  "content_type": "business_profile",
  "content_id": "7f8d9e10-f11a-12b3-c45d-678901234567",
  "submitter_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending",
  "submission_notes": "Updated business description and added new photos.",
  "rejection_reason": null,
  "created_at": "2025-06-05T15:30:00Z",
  "updated_at": "2025-06-05T15:30:00Z",
  "reviewed_at": null,
  "reviewed_by": null
}
```

These examples illustrate the structure and relationships of data in the NAGA VENTURE database. They can be used as references when implementing the application and for testing purposes.
