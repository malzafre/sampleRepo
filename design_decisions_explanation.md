# Design Decisions Explanation for NAGA VENTURE Database Schema

This document explains the key design decisions made in creating the NAGA VENTURE database schema, with a focus on making these decisions understandable for beginners.

## 1. Unified Business Table Approach

**Decision:** Use a single `businesses` table for all business types (accommodations, shops, services) with a `business_type` field.

**Explanation:** 
- **Simplicity:** Having one table for all businesses simplifies queries when you need to search across all business types.
- **Common Fields:** Most information (name, address, contact details) is shared across all business types.
- **Type-Specific Extensions:** Additional tables (like `room_types` for accommodations) extend the base business data when needed.
- **Filtering:** The `business_type` field makes it easy to filter for specific types of businesses.

**Alternative Considered:** Creating separate tables for each business type (accommodations, shops, services). This was rejected because it would lead to duplicated fields and more complex queries when searching across all businesses.

## 2. Hierarchical Category Structure

**Decision:** Implement a two-level category hierarchy with `main_categories` and `sub_categories` tables.

**Explanation:**
- **Flexibility:** Allows for organizing businesses and tourist spots in a logical hierarchy.
- **User Experience:** Makes navigation easier for tourists browsing the platform.
- **Extensibility:** Tourism admin can add or modify categories as needed.
- **Simplified Queries:** Finding all businesses in a main category (e.g., all Food & Beverage businesses) is straightforward.

**Alternative Considered:** Using a self-referencing table with unlimited hierarchy depth. This was rejected as overly complex for the current needs and potentially confusing for users.

## 3. UUID as Primary Key

**Decision:** Use UUID as the primary key type for all tables.

**Explanation:**
- **Supabase Compatibility:** Aligns with Supabase's default approach, which uses UUIDs.
- **Security:** Makes IDs unpredictable, reducing the risk of enumeration attacks.
- **Distributed Systems:** Allows for generating IDs across multiple systems without coordination.
- **Future Scalability:** Eliminates concerns about running out of IDs or ID conflicts during data migrations.

**Alternative Considered:** Using auto-incrementing integers. This was rejected because it doesn't align with Supabase's defaults and could create issues with future scaling.

## 4. Polymorphic Reviews Approach

**Decision:** Implement a polymorphic design for reviews that can reference businesses, tourist spots, or events.

**Explanation:**
- **Code Reuse:** The same review functionality works for all entity types.
- **Consistent User Experience:** Reviews have the same structure regardless of what's being reviewed.
- **Simplified Queries:** Can easily get all reviews by a specific user across all entity types.
- **Constraints:** Database constraints ensure each review is associated with exactly one entity.

**Alternative Considered:** Creating separate review tables for each entity type. This was rejected because it would duplicate code and make it harder to query across all reviews.

## 5. Geographical Data Storage

**Decision:** Use PostGIS `geography` type for location data.

**Explanation:**
- **Accuracy:** Properly handles geographic coordinates on the Earth's surface.
- **Specialized Queries:** Enables distance calculations, proximity searches, and other geospatial operations.
- **Performance:** Includes specialized indexing for geospatial queries.
- **Industry Standard:** PostGIS is the leading spatial database extension for PostgreSQL.

**Alternative Considered:** Storing latitude and longitude as separate numeric fields. This was rejected because it would require custom functions for distance calculations and wouldn't benefit from specialized indexing.

## 6. Content Approval Workflow

**Decision:** Create dedicated tables for tracking content approval requests and content change history.

**Explanation:**
- **Accountability:** Tracks who submitted changes and who approved them.
- **Audit Trail:** Maintains a history of all content changes for reference.
- **Process Management:** Supports the required workflow for content updates.
- **Flexibility:** Works with different content types (businesses, tourist spots, events).

**Alternative Considered:** Using status fields on the content tables themselves. This was rejected because it wouldn't provide a complete history of changes and approvals.

## 7. Row Level Security (RLS)

**Decision:** Implement comprehensive Row Level Security policies for all tables.

**Explanation:**
- **Security at the Database Level:** Enforces access control directly in the database, not just in application code.
- **Role-Based Access:** Different user roles (admin, business owner, tourist) have appropriate access levels.
- **Data Protection:** Ensures users can only see and modify data they're authorized to access.
- **Supabase Integration:** Takes advantage of Supabase's built-in RLS capabilities.

**Alternative Considered:** Implementing access control only in application code. This was rejected because it would be less secure and wouldn't leverage Supabase's security features.

## 8. Automated Triggers and Functions

**Decision:** Use PostgreSQL triggers and functions for automated operations like updating ratings and timestamps.

**Explanation:**
- **Data Consistency:** Ensures derived data (like average ratings) is always up-to-date.
- **Reduced Application Logic:** Moves some logic to the database, simplifying application code.
- **Performance:** Database-level operations are typically faster than application-level calculations.
- **Reliability:** Operations happen automatically, even if application code forgets to update values.

**Alternative Considered:** Handling all calculations in application code. This was rejected because it could lead to inconsistent data if updates are missed.

## 9. Junction Tables for Many-to-Many Relationships

**Decision:** Use junction tables (e.g., `business_categories`) for many-to-many relationships.

**Explanation:**
- **Database Normalization:** Follows standard database design principles.
- **Flexibility:** Allows businesses to belong to multiple categories.
- **Future Extensions:** Junction tables can be extended with additional attributes if needed.
- **Query Efficiency:** Properly indexed junction tables enable efficient queries.

**Alternative Considered:** Using array fields in PostgreSQL. This was rejected because it would make indexing and querying more complex, especially for beginners.

## 10. Separation of Images into Dedicated Tables

**Decision:** Store images in dedicated tables (e.g., `business_images`, `room_images`) rather than as arrays in the main tables.

**Explanation:**
- **Structured Data:** Makes it easier to work with image metadata (captions, display order).
- **Performance:** Avoids loading all images when only basic entity data is needed.
- **Flexibility:** Allows for different image handling for different entity types.
- **Simplicity:** Follows standard relational database patterns that are easier for beginners to understand.

**Alternative Considered:** Storing image URLs as JSON arrays in the main tables. This was rejected because it would make it harder to work with image metadata and wouldn't follow relational database best practices.

## Conclusion

These design decisions were made with several key principles in mind:

1. **Beginner-Friendly:** Using standard relational database patterns that are well-documented and widely understood.
2. **Supabase Best Practices:** Leveraging Supabase's features and following their recommended approaches.
3. **Scalability:** Designing for future growth while keeping the initial implementation straightforward.
4. **Security:** Implementing proper access controls and data protection measures.
5. **Performance:** Optimizing for common query patterns and including appropriate indexes.

The resulting schema provides a solid foundation for the NAGA VENTURE tourism platform while remaining accessible to developers with limited database experience.
