# NAGA VENTURE Database Requirements Analysis

## Project Overview
NAGA VENTURE is a centralized tourism platform for Naga City that aims to provide tourists with easy access to accommodations, tourist spots, local shops, and events. The platform includes features such as interactive maps, booking systems, directories, and user reviews.

## Core Entities Identified

### 1. Users and Authentication
- Multiple user roles: Tourism Admin, Business Listing CMS Manager, Tourism Content CMS Manager, Business Registration Manager, Business Owners, and Tourists
- Role-based access control
- Authentication and password recovery

### 2. Business Listings
- Types: Accommodations, Shops, Services
- Basic information: Name, type, address, contact details
- Descriptive content: Description, images, amenities
- Operational details: Business hours
- Specialized fields based on business type

### 3. Categories
- Hierarchical structure with main categories and subcategories
- Examples:
  - Food & Beverage (main) → Dining, Cafe, Bars (sub)
  - Health & Beauty (main) → Spa, Salon, Pharmacy, Clinic (sub)
  - Technology & Services (main) → Internet, Repair, Printing (sub)
  - Shopping & Retail (main) → Souvenir, Clothing, Jewelry (sub)
- Dynamic category management by Tourism Admin

### 4. Tourist Spots
- Name, description, images, location
- Contact information, operating hours, entry fees
- Categorization (e.g., Existing, Emerging)

### 5. Events
- Name, description, date, time, venue
- Applicable fees, scheduling (start/end dates)
- Categorization

### 6. Reviews & Ratings
- For accommodations, tourist spots, shops, and events
- Star ratings and comments
- Business owner responses

### 7. Booking System
- Room reservations for accommodations
- Payment processing
- Booking confirmations and receipts
- Integration with payment gateways (Gcash mentioned in proposal, PayPal and Xendit in requirements)

### 8. Interactive Map
- Integration with OpenStreetMaps API
- Location pinning for businesses, tourist spots, and events
- Navigation and directions

### 9. Promotions & Special Offers
- Title, description, images, links
- Start and end dates
- Business-specific and platform-wide promotions

### 10. Content Approval Workflow
- Submission of content updates
- Review and approval/rejection process
- Feedback mechanism

### 11. Business Registration & Claiming
- Registration of new businesses
- Claiming of existing listings
- Verification process

## Technical Requirements

### Database Platform
- Supabase (PostgreSQL-based)

### Scalability
- Design for future growth
- Start with static data
- Expected user base: 100-200 initially

### API Integrations
- Google Maps API
- Payment gateways (PayPal, Xendit)
- Future API integrations

### Security
- Row-Level Security (RLS) policies
- Secure authentication
- Data protection

## Constraints
- Beginner-friendly approach
- Well-documented schema
- Performance optimization
- Supabase best practices

## Deliverables
1. Complete SQL schema with CREATE TABLE statements
2. Entity Relationship Diagram (ERD)
3. Explanation of design decisions
4. Setup instructions for Supabase
5. Recommendations for future scaling
