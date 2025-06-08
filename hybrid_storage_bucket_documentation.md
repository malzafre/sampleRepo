# Hybrid Storage Bucket RLS Policies Documentation

## Overview

This document explains the hybrid approach to Row Level Security (RLS) policies for storage buckets in the NAGA VENTURE tourism platform. This approach uses helper functions defined in the public schema and references them from storage policies.

## Why the Hybrid Approach?

The hybrid approach solves a common permission issue in Supabase where regular database roles don't have permission to create functions directly in the storage schema. By defining functions in the public schema and referencing them from storage policies, we maintain sophisticated security while ensuring compatibility with Supabase permissions.

## Storage Bucket Configuration

### 1. business-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 5 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `business_id/filename.ext`

### 2. room-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 8 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `business_id/room_type_id/filename.ext`

### 3. tourist-spot-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 8 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `tourist_spot_id/filename.ext`

### 4. event-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 5 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `event_id/filename.ext`

### 5. review-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 3 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `review_id/filename.ext`

### 6. promotion-images
- **Public Access**: Yes (Public bucket)
- **File Size Limit**: 5 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `promotion_id/filename.ext`

### 7. profile-images
- **Public Access**: No (Private bucket)
- **File Size Limit**: 2 MB per file
- **MIME Types**: image/jpeg, image/png, image/webp
- **Path Structure**: `user_id/filename.ext`

## Helper Functions in Public Schema

The hybrid approach uses helper functions defined in the public schema:

```sql
-- Example: Function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'tourism_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Key helper functions include:
- `public.is_admin()`: Checks if the current user is an admin
- `public.is_tourism_content_manager()`: Checks if the user is a tourism content manager
- `public.is_business_listing_manager()`: Checks if the user is a business listing manager
- `public.is_staff()`: Checks if the user is any type of admin or manager
- `public.owns_business(business_id)`: Checks if the user owns a specific business
- `public.is_review_author(review_id)`: Checks if the user is the author of a review
- `public.owns_promotion(promotion_id)`: Checks if the user owns a promotion
- Path extraction functions like `public.get_business_id_from_path(name)`

## Storage Policies Referencing Public Functions

Storage policies reference these public functions:

```sql
-- Example: Policy for business image uploads
CREATE POLICY "Business owners can upload business images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'business-images' AND
  (
    public.is_staff() OR
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_path(name))
    )
  )
);
```

## Access Control Patterns

The RLS policies follow these access patterns:

1. **Public Read Access**: Most buckets allow public read access except for profile-images
2. **Owner Write Access**: Users can only upload/update/delete their own content
3. **Role-Based Access**: Staff members have elevated permissions based on their roles
4. **Path-Based Security**: File paths include IDs that are used to determine ownership

## Policies by Bucket

### business-images Bucket

- **Read**: Everyone can view business images
- **Write**: Only business owners can upload/update/delete images for their own businesses
- **Staff**: Admins and business listing managers can manage all business images
- **Path Structure**: `business_id/filename.ext`

### room-images Bucket

- **Read**: Everyone can view room images
- **Write**: Only accommodation owners can upload/update/delete images for their own rooms
- **Staff**: Admins and business listing managers can manage all room images
- **Path Structure**: `business_id/room_type_id/filename.ext`

### tourist-spot-images Bucket

- **Read**: Everyone can view tourist spot images
- **Write**: Only tourism content managers and admins can upload/update/delete tourist spot images
- **Path Structure**: `tourist_spot_id/filename.ext`

### event-images Bucket

- **Read**: Everyone can view event images
- **Write**: Only tourism content managers, event creators, and admins can upload/update/delete event images
- **Path Structure**: `event_id/filename.ext`

### review-images Bucket

- **Read**: Everyone can view review images
- **Write**: Only review authors can upload/update/delete images for their own reviews
- **Staff**: Admins can manage all review images
- **Path Structure**: `review_id/filename.ext`

### promotion-images Bucket

- **Read**: Everyone can view promotion images
- **Write**: Only business owners can upload/update/delete images for their own promotions
- **Staff**: Admins and business listing managers can manage all promotion images
- **Path Structure**: `promotion_id/filename.ext`

### profile-images Bucket

- **Read**: Only authenticated users can view profile images
- **Write**: Users can only upload/update/delete their own profile images
- **Staff**: Admins can manage all profile images
- **Path Structure**: `user_id/filename.ext`

## Implementation Notes

1. **Function Location**: All helper functions are defined in the public schema
2. **Function References**: All function references in policies use the `public.` prefix
3. **Path Structure**: The policies rely on a consistent file path structure that includes the relevant ID (business_id, review_id, etc.) as the first segment of the path
4. **Security Definer**: All helper functions use SECURITY DEFINER to ensure they run with the necessary permissions

## How to Apply These Policies

1. Create all storage buckets with the recommended settings
2. Run the hybrid storage bucket RLS policy script (`hybrid_storage_bucket_rls_policies.sql`) in your Supabase SQL editor
3. Test the policies by uploading files as different user types

## Client-Side Implementation

When implementing file uploads in your application:

```javascript
// Example: Uploading a business image
const businessId = '123e4567-e89b-12d3-a456-426614174000';
const filePath = `${businessId}/storefront.jpg`;

const { data, error } = await supabase.storage
  .from('business-images')
  .upload(filePath, fileData, {
    contentType: 'image/jpeg',
    cacheControl: '3600'
  });
```

Always construct the file path to include the appropriate ID as the first segment.

## Troubleshooting

If you encounter permission issues:

1. **Check Role**: Ensure you're running the script with the postgres role selected
2. **Function Location**: Verify all functions are created in the public schema
3. **Function References**: Ensure all function references use the `public.` prefix
4. **Simple Policies**: If issues persist, fall back to simpler policies without function references

## Security Best Practices

1. Always validate file types and sizes on the client side before uploading
2. Use the path structure consistently to ensure RLS policies work correctly
3. Never allow users to specify arbitrary paths
4. Consider implementing additional virus scanning for uploaded files
5. Regularly audit storage usage and clean up unused files

## Advantages of the Hybrid Approach

1. **Permission Compatibility**: Works with standard Supabase permissions
2. **Sophisticated Security**: Maintains path-based access control
3. **Code Organization**: Keeps helper functions in a central location
4. **Reusability**: Functions can be reused across different policies
5. **Maintainability**: Easier to update security logic in one place
