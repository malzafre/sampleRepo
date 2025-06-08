# Row Level Security (RLS) Policies Documentation for NAGA VENTURE

## Introduction

This document explains the Row Level Security (RLS) policies implemented for the NAGA VENTURE tourism platform database. RLS is a security feature in PostgreSQL/Supabase that restricts which rows a user can access in a database table based on their identity and role.

## Why RLS is Important

1. **Data Security**: Ensures users can only access data they're authorized to see
2. **Simplified Application Logic**: Security rules are enforced at the database level, not just in application code
3. **Reduced Risk**: Prevents accidental data exposure even if there are bugs in application code
4. **Scalability**: Security rules apply consistently across all access methods (API, direct SQL)

## User Roles and Permissions

The NAGA VENTURE platform has the following user roles, each with different access levels:

### 1. Tourism Admin
- Full access to all data and operations
- Can manage users, businesses, tourist spots, events, and content
- Can approve/reject content submissions

### 2. Business Listing Manager
- Can manage business listings (shops, accommodations, services)
- Can approve/reject business content updates
- Can manage business-related data (categories, amenities)

### 3. Tourism Content Manager
- Can manage tourist spots and events
- Can create and manage tourism content
- Can access tourism content analytics

### 4. Business Registration Manager
- Can review and approve/reject business registrations
- Can manage business owner accounts

### 5. Business Owner
- Can manage their own business listings
- Can respond to reviews for their businesses
- Can create promotions for their businesses
- Can view bookings for their accommodations

### 6. Tourist (Regular User)
- Can view approved public content
- Can create and manage their own bookings
- Can write and manage their own reviews
- Can view their own profile and activity

## Helper Functions

The RLS implementation uses several helper functions to simplify policy definitions:

- `is_admin()`: Checks if the current user is a tourism admin
- `is_business_listing_manager()`: Checks if the user is a business listing manager
- `is_tourism_content_manager()`: Checks if the user is a tourism content manager
- `is_business_registration_manager()`: Checks if the user is a business registration manager
- `is_business_owner()`: Checks if the user is a business owner
- `is_staff()`: Checks if the user is any type of admin or manager
- `has_permission(permission_name)`: Checks if the user has a specific permission
- `owns_business(business_id)`: Checks if the user owns a specific business

## Policy Patterns

The RLS policies follow these common patterns:

### 1. Public Access Pattern
- Public users can view approved, active, or published content
- Example: `status = 'approved' OR status = 'active'`

### 2. Owner Access Pattern
- Users can manage their own content
- Example: `owner_id = auth.uid()`

### 3. Role-Based Access Pattern
- Access is granted based on user role
- Example: `is_admin() OR is_business_listing_manager()`

### 4. Permission-Based Access Pattern
- Access is granted based on specific permissions
- Example: `has_permission('manage_businesses')`

### 5. Relationship-Based Access Pattern
- Access to related data is based on access to the parent data
- Example: Business owners can access reviews for their businesses

## Policies by Entity Type

### Profiles and Authentication

- **Public**: Can view basic profile information
- **Self**: Users can update their own profiles
- **Admin**: Only admins can delete profiles or manage staff permissions

### Categories

- **Public**: Everyone can view active categories and subcategories
- **Admin/Manager**: Only admins and staff with category management permission can create, update, or delete categories

### Businesses

- **Public**: Can view approved businesses and their related data (images, hours, amenities)
- **Owner**: Business owners can view and update their own businesses and related data
- **Admin/Manager**: Admins and business listing managers can manage all businesses
- **Registration Manager**: Can approve/reject business registrations

### Accommodations

- **Public**: Can view room types, images, and amenities for approved accommodations
- **Owner**: Accommodation owners can manage their room data
- **Admin/Manager**: Admins and business listing managers can manage all accommodation data

### Bookings

- **Guest**: Users can view and manage their own bookings
- **Business Owner**: Can view bookings for their accommodations
- **Admin**: Can view and manage all bookings
- **Payment Transactions**: Similar access patterns as bookings

### Tourist Spots

- **Public**: Can view active tourist spots and related data
- **Admin/Manager**: Only admins and tourism content managers can manage tourist spots

### Events

- **Public**: Can view upcoming and ongoing events
- **Business Owner**: Can view events at their business
- **Admin/Manager**: Only admins and tourism content managers can manage events

### Reviews and Ratings

- **Public**: Can view approved reviews
- **Self**: Users can view, create, update, and delete their own reviews
- **Business Owner**: Can view all reviews for their businesses and respond to them
- **Admin/Manager**: Can manage all reviews and responses

### Promotions

- **Public**: Can view active promotions
- **Business Owner**: Can manage promotions for their own businesses
- **Admin/Manager**: Can manage all promotions

### Content Approval Workflow

- **Self**: Users can view and create their own approval requests
- **Admin/Manager**: Can view and manage all approval requests
- **Business Owner**: Can view approval requests for their businesses

### API Integration and System Data

- **Admin**: Only admins can view and manage API integrations and system logs
- **Self**: Users can view their own page views and logs

## Implementation Details

### Policy Types

Each table has policies for different operations:

- **SELECT**: Controls which rows users can read
- **INSERT**: Controls which rows users can add
- **UPDATE**: Controls which rows users can modify
- **DELETE**: Controls which rows users can remove
- **ALL**: Applies to all operations

### Policy Conditions

Policies use two types of conditions:

- **USING**: Applied for SELECT, UPDATE, and DELETE operations
- **WITH CHECK**: Applied for INSERT and UPDATE operations

## How to Apply These Policies

1. The complete RLS policy script (`complete_rls_policies.sql`) should be run after creating all tables but before adding any data
2. All tables have RLS enabled with `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY`
3. Each policy is created with `CREATE POLICY policy_name ON table_name FOR operation USING (condition)`
4. Helper functions are created at the beginning of the script

## Testing RLS Policies

To test if the policies are working correctly:

1. Create users with different roles
2. Sign in as each user type
3. Attempt to perform various operations (view, create, update, delete)
4. Verify that users can only access data they're authorized to see

## Common Issues and Troubleshooting

1. **No Data Visible**: If users can't see any data, check if RLS is too restrictive
2. **Policy Conflicts**: If multiple policies apply to the same table, they are combined with OR logic
3. **Performance Impact**: Complex policies can impact query performance; monitor and optimize as needed
4. **Auth Context**: RLS relies on `auth.uid()`; ensure authentication is properly set up

## Customizing Policies

These policies can be customized based on specific requirements:

1. Modify the conditions in existing policies
2. Add new policies for special cases
3. Create additional helper functions for complex conditions
4. Adjust policies as the application evolves

## Security Best Practices

1. Always test RLS policies thoroughly
2. Never disable RLS for production tables
3. Use the principle of least privilege
4. Regularly audit and review policies
5. Keep helper functions simple and focused

## Conclusion

The RLS policies implemented for NAGA VENTURE provide comprehensive security at the database level, ensuring that users can only access and modify data appropriate to their role. These policies complement application-level security and provide an additional layer of protection for sensitive data.
