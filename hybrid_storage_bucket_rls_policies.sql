-- =================================================================
-- HYBRID STORAGE BUCKET RLS POLICIES FOR NAGA VENTURE
-- =================================================================
-- This script contains RLS policies for all storage buckets in the NAGA VENTURE database
-- Created: June 8, 2025
-- Updated: June 8, 2025 - Hybrid approach with public schema functions

-- =================================================================
-- HELPER FUNCTIONS FOR STORAGE RLS POLICIES (IN PUBLIC SCHEMA)
-- =================================================================

-- Function to check if the current user is an admin
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

-- Function to check if the current user is a tourism content manager
CREATE OR REPLACE FUNCTION public.is_tourism_content_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'tourism_content_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a business listing manager
CREATE OR REPLACE FUNCTION public.is_business_listing_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'business_listing_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user has staff permissions
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('tourism_admin', 'business_listing_manager', 'tourism_content_manager', 'business_registration_manager')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user owns a business
CREATE OR REPLACE FUNCTION public.owns_business(business_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = business_id
    AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to extract business ID from a file path
CREATE OR REPLACE FUNCTION public.get_business_id_from_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  business_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: business_id/filename.ext
  IF array_length(path_parts, 1) >= 2 THEN
    BEGIN
      business_id := path_parts[1]::UUID;
      RETURN business_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- BUSINESS IMAGES BUCKET POLICIES
-- =================================================================

-- Enable RLS on business-images bucket
CREATE POLICY "Public can view business images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'business-images'
);

-- Only business owners and staff can insert business images
CREATE POLICY "Business owners can upload business images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'business-images' AND
  (
    -- Staff can upload any business images
    public.is_staff() OR
    -- Business owners can upload their own business images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_path(name))
    )
  )
);

-- Only business owners and staff can update business images
CREATE POLICY "Business owners can update business images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'business-images' AND
  (
    -- Staff can update any business images
    public.is_staff() OR
    -- Business owners can update their own business images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_path(name))
    )
  )
);

-- Only business owners and staff can delete business images
CREATE POLICY "Business owners can delete business images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'business-images' AND
  (
    -- Staff can delete any business images
    public.is_staff() OR
    -- Business owners can delete their own business images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_path(name))
    )
  )
);

-- =================================================================
-- ROOM IMAGES BUCKET POLICIES
-- =================================================================

-- Function to extract business ID from a room image path
CREATE OR REPLACE FUNCTION public.get_business_id_from_room_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  business_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: business_id/room_type_id/filename.ext
  IF array_length(path_parts, 1) >= 3 THEN
    BEGIN
      business_id := path_parts[1]::UUID;
      RETURN business_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on room-images bucket
CREATE POLICY "Public can view room images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'room-images'
);

-- Only accommodation owners and staff can insert room images
CREATE POLICY "Accommodation owners can upload room images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'room-images' AND
  (
    -- Staff can upload any room images
    public.is_staff() OR
    -- Accommodation owners can upload their own room images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_room_path(name))
    )
  )
);

-- Only accommodation owners and staff can update room images
CREATE POLICY "Accommodation owners can update room images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'room-images' AND
  (
    -- Staff can update any room images
    public.is_staff() OR
    -- Accommodation owners can update their own room images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_room_path(name))
    )
  )
);

-- Only accommodation owners and staff can delete room images
CREATE POLICY "Accommodation owners can delete room images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'room-images' AND
  (
    -- Staff can delete any room images
    public.is_staff() OR
    -- Accommodation owners can delete their own room images
    (
      auth.uid() IS NOT NULL AND
      public.owns_business(public.get_business_id_from_room_path(name))
    )
  )
);

-- =================================================================
-- TOURIST SPOT IMAGES BUCKET POLICIES
-- =================================================================

-- Enable RLS on tourist-spot-images bucket
CREATE POLICY "Public can view tourist spot images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'tourist-spot-images'
);

-- Only tourism content managers and admins can insert tourist spot images
CREATE POLICY "Staff can upload tourist spot images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'tourist-spot-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager()
  )
);

-- Only tourism content managers and admins can update tourist spot images
CREATE POLICY "Staff can update tourist spot images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'tourist-spot-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager()
  )
);

-- Only tourism content managers and admins can delete tourist spot images
CREATE POLICY "Staff can delete tourist spot images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'tourist-spot-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager()
  )
);

-- =================================================================
-- EVENT IMAGES BUCKET POLICIES
-- =================================================================

-- Function to check if the current user created an event
CREATE OR REPLACE FUNCTION public.created_event(event_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.events
    WHERE id = event_id
    AND created_by = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to extract event ID from a file path
CREATE OR REPLACE FUNCTION public.get_event_id_from_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  event_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: event_id/filename.ext
  IF array_length(path_parts, 1) >= 2 THEN
    BEGIN
      event_id := path_parts[1]::UUID;
      RETURN event_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on event-images bucket
CREATE POLICY "Public can view event images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'event-images'
);

-- Only tourism content managers, event creators, and admins can insert event images
CREATE POLICY "Staff and event creators can upload event images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'event-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager() OR
    -- Event creators can upload their own event images
    (
      auth.uid() IS NOT NULL AND
      public.created_event(public.get_event_id_from_path(name))
    )
  )
);

-- Only tourism content managers, event creators, and admins can update event images
CREATE POLICY "Staff and event creators can update event images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'event-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager() OR
    -- Event creators can update their own event images
    (
      auth.uid() IS NOT NULL AND
      public.created_event(public.get_event_id_from_path(name))
    )
  )
);

-- Only tourism content managers, event creators, and admins can delete event images
CREATE POLICY "Staff and event creators can delete event images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'event-images' AND
  (
    public.is_admin() OR
    public.is_tourism_content_manager() OR
    -- Event creators can delete their own event images
    (
      auth.uid() IS NOT NULL AND
      public.created_event(public.get_event_id_from_path(name))
    )
  )
);

-- =================================================================
-- REVIEW IMAGES BUCKET POLICIES
-- =================================================================

-- Enable RLS on review-images bucket
CREATE POLICY "Public can view review images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'review-images'
);

-- Function to check if the current user is the author of a review
CREATE OR REPLACE FUNCTION public.is_review_author(review_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.reviews
    WHERE id = review_id
    AND reviewer_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to extract review ID from a file path
CREATE OR REPLACE FUNCTION public.get_review_id_from_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  review_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: review_id/filename.ext
  IF array_length(path_parts, 1) >= 2 THEN
    BEGIN
      review_id := path_parts[1]::UUID;
      RETURN review_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only review authors can insert review images
CREATE POLICY "Review authors can upload review images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'review-images' AND
  (
    -- Staff can upload any review images
    public.is_staff() OR
    -- Review authors can upload their own review images
    (
      auth.uid() IS NOT NULL AND
      public.is_review_author(public.get_review_id_from_path(name))
    )
  )
);

-- Only review authors can update review images
CREATE POLICY "Review authors can update review images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'review-images' AND
  (
    -- Staff can update any review images
    public.is_staff() OR
    -- Review authors can update their own review images
    (
      auth.uid() IS NOT NULL AND
      public.is_review_author(public.get_review_id_from_path(name))
    )
  )
);

-- Only review authors can delete review images
CREATE POLICY "Review authors can delete review images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'review-images' AND
  (
    -- Staff can delete any review images
    public.is_staff() OR
    -- Review authors can delete their own review images
    (
      auth.uid() IS NOT NULL AND
      public.is_review_author(public.get_review_id_from_path(name))
    )
  )
);

-- =================================================================
-- PROMOTION IMAGES BUCKET POLICIES
-- =================================================================

-- Enable RLS on promotion-images bucket
CREATE POLICY "Public can view promotion images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'promotion-images'
);

-- Function to check if the current user owns a promotion
CREATE OR REPLACE FUNCTION public.owns_promotion(promotion_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.promotions
    JOIN public.businesses ON promotions.business_id = businesses.id
    WHERE promotions.id = promotion_id
    AND businesses.owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to extract promotion ID from a file path
CREATE OR REPLACE FUNCTION public.get_promotion_id_from_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  promotion_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: promotion_id/filename.ext
  IF array_length(path_parts, 1) >= 2 THEN
    BEGIN
      promotion_id := path_parts[1]::UUID;
      RETURN promotion_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only business owners and staff can insert promotion images
CREATE POLICY "Business owners can upload promotion images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'promotion-images' AND
  (
    -- Staff can upload any promotion images
    public.is_staff() OR
    -- Business owners can upload their own promotion images
    (
      auth.uid() IS NOT NULL AND
      public.owns_promotion(public.get_promotion_id_from_path(name))
    )
  )
);

-- Only business owners and staff can update promotion images
CREATE POLICY "Business owners can update promotion images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'promotion-images' AND
  (
    -- Staff can update any promotion images
    public.is_staff() OR
    -- Business owners can update their own promotion images
    (
      auth.uid() IS NOT NULL AND
      public.owns_promotion(public.get_promotion_id_from_path(name))
    )
  )
);

-- Only business owners and staff can delete promotion images
CREATE POLICY "Business owners can delete promotion images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'promotion-images' AND
  (
    -- Staff can delete any promotion images
    public.is_staff() OR
    -- Business owners can delete their own promotion images
    (
      auth.uid() IS NOT NULL AND
      public.owns_promotion(public.get_promotion_id_from_path(name))
    )
  )
);

-- =================================================================
-- PROFILE IMAGES BUCKET POLICIES
-- =================================================================

-- Enable RLS on profile-images bucket
-- Only authenticated users can view profile images
CREATE POLICY "Authenticated users can view profile images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'profile-images' AND
  auth.uid() IS NOT NULL
);

-- Function to extract user ID from a profile image path
CREATE OR REPLACE FUNCTION public.get_user_id_from_profile_path(file_path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  user_id UUID;
BEGIN
  path_parts := string_to_array(file_path, '/');
  
  -- Assuming path format: user_id/filename.ext
  IF array_length(path_parts, 1) >= 2 THEN
    BEGIN
      user_id := path_parts[1]::UUID;
      RETURN user_id;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users can only upload their own profile images
CREATE POLICY "Users can upload their own profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images' AND
  (
    -- Staff can upload any profile images
    public.is_staff() OR
    -- Users can upload their own profile images
    (
      auth.uid() IS NOT NULL AND
      public.get_user_id_from_profile_path(name) = auth.uid()
    )
  )
);

-- Users can only update their own profile images
CREATE POLICY "Users can update their own profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images' AND
  (
    -- Staff can update any profile images
    public.is_staff() OR
    -- Users can update their own profile images
    (
      auth.uid() IS NOT NULL AND
      public.get_user_id_from_profile_path(name) = auth.uid()
    )
  )
);

-- Users can only delete their own profile images
CREATE POLICY "Users can delete their own profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images' AND
  (
    -- Staff can delete any profile images
    public.is_staff() OR
    -- Users can delete their own profile images
    (
      auth.uid() IS NOT NULL AND
      public.get_user_id_from_profile_path(name) = auth.uid()
    )
  )
);
