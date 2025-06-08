# Entity Relationship Diagram (ERD) Description for NAGA VENTURE

## Core Entities and Relationships

### Authentication & User Management
- **profiles**: Extends Supabase auth.users, stores user information and role
- **staff_permissions**: Stores detailed permissions for admin and manager roles
- Relationship: One-to-one between profiles and staff_permissions

### Categories
- **main_categories**: Stores top-level categories (e.g., Food & Beverage)
- **sub_categories**: Stores subcategories (e.g., Dining, Cafe)
- Relationship: One-to-many between main_categories and sub_categories

### Business Listings
- **businesses**: Central table for all business listings (accommodations, shops, services)
- **business_categories**: Junction table linking businesses to subcategories
- **business_images**: Stores images for businesses
- **business_hours**: Stores operating hours for businesses
- **amenities**: List of possible amenities
- **business_amenities**: Junction table linking businesses to amenities
- Relationships:
  - One-to-many between businesses and business_images/business_hours
  - Many-to-many between businesses and sub_categories (via business_categories)
  - Many-to-many between businesses and amenities (via business_amenities)

### Accommodation-Specific
- **room_types**: Stores room types for accommodation businesses
- **room_images**: Stores images for room types
- **room_amenities**: Junction table linking room types to amenities
- Relationships:
  - One-to-many between businesses and room_types (filtered by business_type)
  - One-to-many between room_types and room_images
  - Many-to-many between room_types and amenities (via room_amenities)

### Booking System
- **bookings**: Stores accommodation booking information
- **payment_transactions**: Stores payment transaction records
- Relationships:
  - Many-to-one between bookings and profiles (guest_id)
  - Many-to-one between bookings and businesses
  - Many-to-one between bookings and room_types
  - One-to-many between bookings and payment_transactions

### Tourist Spots
- **tourist_spots**: Stores tourist attraction information
- **tourist_spot_categories**: Junction table linking tourist spots to subcategories
- **tourist_spot_images**: Stores images for tourist spots
- Relationships:
  - One-to-many between tourist_spots and tourist_spot_images
  - Many-to-many between tourist_spots and sub_categories (via tourist_spot_categories)

### Events
- **events**: Stores event information
- **event_categories**: Junction table linking events to subcategories
- **event_images**: Stores images for events
- Relationships:
  - One-to-many between events and event_images
  - Many-to-many between events and sub_categories (via event_categories)
  - Optional many-to-one between events and tourist_spots/businesses (for venue)

### Reviews & Ratings
- **reviews**: Stores user reviews for businesses, tourist spots, and events
- **review_responses**: Stores responses to reviews
- **review_images**: Stores images attached to reviews
- Relationships:
  - Many-to-one between reviews and profiles (reviewer_id)
  - Many-to-one between reviews and businesses/tourist_spots/events (polymorphic)
  - One-to-many between reviews and review_responses/review_images

### Promotions & Special Offers
- **promotions**: Stores promotion information
- **promotion_images**: Stores images for promotions
- Relationships:
  - Optional many-to-one between promotions and businesses
  - One-to-many between promotions and promotion_images

### Content Approval Workflow
- **content_approval_requests**: Stores content approval requests
- **content_change_history**: Stores history of content changes
- Relationships:
  - Many-to-one between content_approval_requests and profiles (submitter_id, reviewer_id)
  - Polymorphic relationship to various content types

### API Integration
- **api_integrations**: Stores configuration for external API integrations

### Analytics & Logging
- **page_views**: Stores analytics for page views
- **system_logs**: Stores system-wide logs
- Relationships:
  - Optional many-to-one between page_views and profiles (viewer_id)
  - Optional many-to-one between system_logs and profiles (user_id)

## Key Design Decisions

1. **Unified Business Table**: All business types (accommodations, shops, services) are stored in a single table with a business_type field, allowing for common operations while supporting type-specific extensions.

2. **Hierarchical Categories**: Two-level category structure with main_categories and sub_categories tables, allowing for flexible categorization.

3. **Polymorphic Reviews**: The reviews table uses a polymorphic approach with review_type and corresponding ID fields, allowing reviews to be associated with different entity types.

4. **Geographical Data**: Location data is stored using PostGIS geography type for proper geospatial indexing and queries.

5. **Content Approval Workflow**: Separate tables for tracking approval requests and content change history, supporting the required workflow.

6. **Flexible API Integration**: The api_integrations table allows for storing configuration for various external APIs.

7. **Comprehensive Security**: Row-Level Security policies are implemented for all tables, ensuring proper access control.

8. **Automated Triggers**: Functions and triggers for common operations like updating ratings, generating booking numbers, and maintaining timestamps.

## Database Constraints

1. **Referential Integrity**: Foreign key constraints ensure data consistency across related tables.

2. **Check Constraints**: Various check constraints enforce business rules (e.g., valid date ranges, rating values).

3. **Unique Constraints**: Prevent duplicate entries where appropriate.

4. **Not Null Constraints**: Ensure required fields are always provided.

5. **Custom Constraints**: Complex business rules enforced through custom check constraints (e.g., ensuring business_type matches related tables).
