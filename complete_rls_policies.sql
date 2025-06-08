-- =================================================================
-- COMPLETE ROW LEVEL SECURITY POLICIES FOR NAGA VENTURE
-- =================================================================
-- This script contains comprehensive RLS policies for all tables in the NAGA VENTURE database
-- Created: June 8, 2025

-- =================================================================
-- HELPER FUNCTIONS FOR RLS POLICIES
-- =================================================================

-- Function to check if the current user is an admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'tourism_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a business listing manager
CREATE OR REPLACE FUNCTION is_business_listing_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'business_listing_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a tourism content manager
CREATE OR REPLACE FUNCTION is_tourism_content_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'tourism_content_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a business registration manager
CREATE OR REPLACE FUNCTION is_business_registration_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'business_registration_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a business owner
CREATE OR REPLACE FUNCTION is_business_owner()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'business_owner'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user is a staff member (any admin or manager role)
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('tourism_admin', 'business_listing_manager', 'tourism_content_manager', 'business_registration_manager')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user has specific staff permission
CREATE OR REPLACE FUNCTION has_permission(permission_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM staff_permissions
    WHERE profile_id = auth.uid()
    AND (
      CASE
        WHEN permission_name = 'manage_users' THEN can_manage_users = true
        WHEN permission_name = 'manage_businesses' THEN can_manage_businesses = true
        WHEN permission_name = 'manage_tourist_spots' THEN can_manage_tourist_spots = true
        WHEN permission_name = 'manage_events' THEN can_manage_events = true
        WHEN permission_name = 'approve_content' THEN can_approve_content = true
        WHEN permission_name = 'manage_categories' THEN can_manage_categories = true
        ELSE false
      END
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if the current user owns a business
CREATE OR REPLACE FUNCTION owns_business(business_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM businesses
    WHERE id = business_id
    AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- PROFILES & AUTHENTICATION
-- =================================================================

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Everyone can view basic profile information
CREATE POLICY profiles_select_public ON profiles
  FOR SELECT USING (true);

-- Users can update their own profiles
CREATE POLICY profiles_update_own ON profiles
  FOR UPDATE USING (id = auth.uid());

-- Only admins can delete profiles
CREATE POLICY profiles_delete_admin ON profiles
  FOR DELETE USING (is_admin());

-- Only admins can insert profiles (though this is mostly handled by the auth trigger)
CREATE POLICY profiles_insert_admin ON profiles
  FOR INSERT WITH CHECK (is_admin() OR id = auth.uid());

-- Enable RLS on staff_permissions table
ALTER TABLE staff_permissions ENABLE ROW LEVEL SECURITY;

-- Staff members can view permissions
CREATE POLICY staff_permissions_select_staff ON staff_permissions
  FOR SELECT USING (is_staff());

-- Only admins can manage permissions
CREATE POLICY staff_permissions_all_admin ON staff_permissions
  FOR ALL USING (is_admin());

-- =================================================================
-- CATEGORIES
-- =================================================================

-- Enable RLS on main_categories table
ALTER TABLE main_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view active categories
CREATE POLICY main_categories_select_public ON main_categories
  FOR SELECT USING (is_active = true OR is_staff());

-- Only admins and staff with manage_categories permission can manage categories
CREATE POLICY main_categories_all_admin ON main_categories
  FOR ALL USING (is_admin() OR has_permission('manage_categories'));

-- Enable RLS on sub_categories table
ALTER TABLE sub_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view active subcategories
CREATE POLICY sub_categories_select_public ON sub_categories
  FOR SELECT USING (is_active = true OR is_staff());

-- Only admins and staff with manage_categories permission can manage subcategories
CREATE POLICY sub_categories_all_admin ON sub_categories
  FOR ALL USING (is_admin() OR has_permission('manage_categories'));

-- =================================================================
-- BUSINESSES
-- =================================================================

-- Enable RLS on businesses table
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

-- Public can view approved businesses
CREATE POLICY businesses_select_public ON businesses
  FOR SELECT USING (status = 'approved');

-- Staff can view all businesses
CREATE POLICY businesses_select_staff ON businesses
  FOR SELECT USING (is_staff());

-- Business owners can view their own businesses regardless of status
CREATE POLICY businesses_select_owner ON businesses
  FOR SELECT USING (owner_id = auth.uid());

-- Business owners can update their own businesses
CREATE POLICY businesses_update_owner ON businesses
  FOR UPDATE USING (owner_id = auth.uid());

-- Admins and business listing managers can manage all businesses
CREATE POLICY businesses_all_admin ON businesses
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Business registration managers can approve/reject businesses
CREATE POLICY businesses_update_registration_manager ON businesses
  FOR UPDATE USING (is_business_registration_manager());

-- Business owners can insert new businesses
CREATE POLICY businesses_insert_owner ON businesses
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND 
    (owner_id = auth.uid() OR owner_id IS NULL)
  );

-- Enable RLS on business_categories table
ALTER TABLE business_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view business categories for approved businesses
CREATE POLICY business_categories_select_public ON business_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage categories for their own businesses
CREATE POLICY business_categories_all_owner ON business_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all business categories
CREATE POLICY business_categories_all_admin ON business_categories
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on business_images table
ALTER TABLE business_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view images for approved businesses
CREATE POLICY business_images_select_public ON business_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage images for their own businesses
CREATE POLICY business_images_all_owner ON business_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all business images
CREATE POLICY business_images_all_admin ON business_images
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on business_hours table
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;

-- Everyone can view hours for approved businesses
CREATE POLICY business_hours_select_public ON business_hours
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage hours for their own businesses
CREATE POLICY business_hours_all_owner ON business_hours
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all business hours
CREATE POLICY business_hours_all_admin ON business_hours
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on amenities table
ALTER TABLE amenities ENABLE ROW LEVEL SECURITY;

-- Everyone can view amenities
CREATE POLICY amenities_select_public ON amenities
  FOR SELECT USING (true);

-- Only admins and business listing managers can manage amenities
CREATE POLICY amenities_all_admin ON amenities
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on business_amenities table
ALTER TABLE business_amenities ENABLE ROW LEVEL SECURITY;

-- Everyone can view amenities for approved businesses
CREATE POLICY business_amenities_select_public ON business_amenities
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage amenities for their own businesses
CREATE POLICY business_amenities_all_owner ON business_amenities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all business amenities
CREATE POLICY business_amenities_all_admin ON business_amenities
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- =================================================================
-- ACCOMMODATION-SPECIFIC TABLES
-- =================================================================

-- Enable RLS on room_types table
ALTER TABLE room_types ENABLE ROW LEVEL SECURITY;

-- Everyone can view room types for approved accommodations
CREATE POLICY room_types_select_public ON room_types
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.business_type = 'accommodation'
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage room types for their own accommodations
CREATE POLICY room_types_all_owner ON room_types
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all room types
CREATE POLICY room_types_all_admin ON room_types
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on room_images table
ALTER TABLE room_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view room images for approved accommodations
CREATE POLICY room_images_select_public ON room_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM room_types
      JOIN businesses ON room_types.business_id = businesses.id
      WHERE room_types.id = room_type_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage room images for their own accommodations
CREATE POLICY room_images_all_owner ON room_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM room_types
      JOIN businesses ON room_types.business_id = businesses.id
      WHERE room_types.id = room_type_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all room images
CREATE POLICY room_images_all_admin ON room_images
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on room_amenities table
ALTER TABLE room_amenities ENABLE ROW LEVEL SECURITY;

-- Everyone can view room amenities for approved accommodations
CREATE POLICY room_amenities_select_public ON room_amenities
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM room_types
      JOIN businesses ON room_types.business_id = businesses.id
      WHERE room_types.id = room_type_id
      AND (businesses.status = 'approved' OR is_staff() OR businesses.owner_id = auth.uid())
    )
  );

-- Business owners can manage room amenities for their own accommodations
CREATE POLICY room_amenities_all_owner ON room_amenities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM room_types
      JOIN businesses ON room_types.business_id = businesses.id
      WHERE room_types.id = room_type_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all room amenities
CREATE POLICY room_amenities_all_admin ON room_amenities
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- =================================================================
-- BOOKING SYSTEM
-- =================================================================

-- Enable RLS on bookings table
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Guests can view their own bookings
CREATE POLICY bookings_select_guest ON bookings
  FOR SELECT USING (guest_id = auth.uid());

-- Business owners can view bookings for their businesses
CREATE POLICY bookings_select_business ON bookings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins can view all bookings
CREATE POLICY bookings_select_admin ON bookings
  FOR SELECT USING (is_admin());

-- Guests can create bookings
CREATE POLICY bookings_insert_guest ON bookings
  FOR INSERT WITH CHECK (guest_id = auth.uid());

-- Guests can update their own bookings (e.g., cancel)
CREATE POLICY bookings_update_guest ON bookings
  FOR UPDATE USING (
    guest_id = auth.uid() AND
    status NOT IN ('completed', 'no_show')
  );

-- Business owners can update bookings for their businesses
CREATE POLICY bookings_update_business ON bookings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins can manage all bookings
CREATE POLICY bookings_all_admin ON bookings
  FOR ALL USING (is_admin());

-- Enable RLS on payment_transactions table
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Guests can view their own payment transactions
CREATE POLICY payment_transactions_select_guest ON payment_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = booking_id
      AND bookings.guest_id = auth.uid()
    )
  );

-- Business owners can view payment transactions for their businesses
CREATE POLICY payment_transactions_select_business ON payment_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      JOIN businesses ON bookings.business_id = businesses.id
      WHERE bookings.id = booking_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins can view all payment transactions
CREATE POLICY payment_transactions_select_admin ON payment_transactions
  FOR SELECT USING (is_admin());

-- Only system and admins can create/update payment transactions
CREATE POLICY payment_transactions_all_admin ON payment_transactions
  FOR ALL USING (is_admin());

-- =================================================================
-- TOURIST SPOTS
-- =================================================================

-- Enable RLS on tourist_spots table
ALTER TABLE tourist_spots ENABLE ROW LEVEL SECURITY;

-- Everyone can view active tourist spots
CREATE POLICY tourist_spots_select_public ON tourist_spots
  FOR SELECT USING (status = 'active' OR is_staff());

-- Only admins and tourism content managers can manage tourist spots
CREATE POLICY tourist_spots_all_admin ON tourist_spots
  FOR ALL USING (is_admin() OR has_permission('manage_tourist_spots'));

-- Enable RLS on tourist_spot_categories table
ALTER TABLE tourist_spot_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view categories for active tourist spots
CREATE POLICY tourist_spot_categories_select_public ON tourist_spot_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tourist_spots
      WHERE tourist_spots.id = tourist_spot_id
      AND (tourist_spots.status = 'active' OR is_staff())
    )
  );

-- Only admins and tourism content managers can manage tourist spot categories
CREATE POLICY tourist_spot_categories_all_admin ON tourist_spot_categories
  FOR ALL USING (is_admin() OR has_permission('manage_tourist_spots'));

-- Enable RLS on tourist_spot_images table
ALTER TABLE tourist_spot_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view images for active tourist spots
CREATE POLICY tourist_spot_images_select_public ON tourist_spot_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tourist_spots
      WHERE tourist_spots.id = tourist_spot_id
      AND (tourist_spots.status = 'active' OR is_staff())
    )
  );

-- Only admins and tourism content managers can manage tourist spot images
CREATE POLICY tourist_spot_images_all_admin ON tourist_spot_images
  FOR ALL USING (is_admin() OR has_permission('manage_tourist_spots'));

-- =================================================================
-- EVENTS
-- =================================================================

-- Enable RLS on events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Everyone can view upcoming and ongoing events
CREATE POLICY events_select_public ON events
  FOR SELECT USING (status IN ('upcoming', 'ongoing') OR is_staff());

-- Only admins and tourism content managers can manage events
CREATE POLICY events_all_admin ON events
  FOR ALL USING (is_admin() OR has_permission('manage_events'));

-- Business owners can view events at their business
CREATE POLICY events_select_business ON events
  FOR SELECT USING (
    business_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Enable RLS on event_categories table
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view categories for public events
CREATE POLICY event_categories_select_public ON event_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_id
      AND (events.status IN ('upcoming', 'ongoing') OR is_staff())
    )
  );

-- Only admins and tourism content managers can manage event categories
CREATE POLICY event_categories_all_admin ON event_categories
  FOR ALL USING (is_admin() OR has_permission('manage_events'));

-- Enable RLS on event_images table
ALTER TABLE event_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view images for public events
CREATE POLICY event_images_select_public ON event_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_id
      AND (events.status IN ('upcoming', 'ongoing') OR is_staff())
    )
  );

-- Only admins and tourism content managers can manage event images
CREATE POLICY event_images_all_admin ON event_images
  FOR ALL USING (is_admin() OR has_permission('manage_events'));

-- =================================================================
-- REVIEWS & RATINGS
-- =================================================================

-- Enable RLS on reviews table
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Everyone can view approved reviews
CREATE POLICY reviews_select_public ON reviews
  FOR SELECT USING (is_approved = true OR is_staff());

-- Users can view their own reviews regardless of approval status
CREATE POLICY reviews_select_own ON reviews
  FOR SELECT USING (reviewer_id = auth.uid());

-- Users can create reviews
CREATE POLICY reviews_insert_user ON reviews
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND
    reviewer_id = auth.uid()
  );

-- Users can update their own reviews
CREATE POLICY reviews_update_own ON reviews
  FOR UPDATE USING (reviewer_id = auth.uid());

-- Users can delete their own reviews
CREATE POLICY reviews_delete_own ON reviews
  FOR DELETE USING (reviewer_id = auth.uid());

-- Admins and content managers can manage all reviews
CREATE POLICY reviews_all_admin ON reviews
  FOR ALL USING (is_admin() OR has_permission('approve_content'));

-- Business owners can view all reviews for their businesses
CREATE POLICY reviews_select_business ON reviews
  FOR SELECT USING (
    review_type = 'business' AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Enable RLS on review_responses table
ALTER TABLE review_responses ENABLE ROW LEVEL SECURITY;

-- Everyone can view responses to approved reviews
CREATE POLICY review_responses_select_public ON review_responses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews
      WHERE reviews.id = review_id
      AND (reviews.is_approved = true OR is_staff() OR reviews.reviewer_id = auth.uid())
    )
  );

-- Users can create/update/delete their own responses
CREATE POLICY review_responses_all_own ON review_responses
  FOR ALL USING (responder_id = auth.uid());

-- Business owners can respond to reviews for their businesses
CREATE POLICY review_responses_insert_business ON review_responses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM reviews
      WHERE reviews.id = review_id AND
      (
        (reviews.review_type = 'business' AND
         EXISTS (
           SELECT 1 FROM businesses
           WHERE businesses.id = reviews.business_id
           AND businesses.owner_id = auth.uid()
         ))
      )
    )
  );

-- Admins can manage all review responses
CREATE POLICY review_responses_all_admin ON review_responses
  FOR ALL USING (is_admin());

-- Enable RLS on review_images table
ALTER TABLE review_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view images for approved reviews
CREATE POLICY review_images_select_public ON review_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews
      WHERE reviews.id = review_id
      AND (reviews.is_approved = true OR is_staff() OR reviews.reviewer_id = auth.uid())
    )
  );

-- Users can manage images for their own reviews
CREATE POLICY review_images_all_own ON review_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM reviews
      WHERE reviews.id = review_id
      AND reviews.reviewer_id = auth.uid()
    )
  );

-- Admins can manage all review images
CREATE POLICY review_images_all_admin ON review_images
  FOR ALL USING (is_admin());

-- =================================================================
-- PROMOTIONS & SPECIAL OFFERS
-- =================================================================

-- Enable RLS on promotions table
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- Everyone can view active promotions
CREATE POLICY promotions_select_public ON promotions
  FOR SELECT USING (status = 'active' OR is_staff());

-- Business owners can view and manage their own promotions
CREATE POLICY promotions_all_business ON promotions
  FOR ALL USING (
    business_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = business_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all promotions
CREATE POLICY promotions_all_admin ON promotions
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- Enable RLS on promotion_images table
ALTER TABLE promotion_images ENABLE ROW LEVEL SECURITY;

-- Everyone can view images for active promotions
CREATE POLICY promotion_images_select_public ON promotion_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM promotions
      WHERE promotions.id = promotion_id
      AND (promotions.status = 'active' OR is_staff())
    )
  );

-- Business owners can manage images for their own promotions
CREATE POLICY promotion_images_all_business ON promotion_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM promotions
      JOIN businesses ON promotions.business_id = businesses.id
      WHERE promotions.id = promotion_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Admins and business listing managers can manage all promotion images
CREATE POLICY promotion_images_all_admin ON promotion_images
  FOR ALL USING (is_admin() OR has_permission('manage_businesses'));

-- =================================================================
-- CONTENT APPROVAL WORKFLOW
-- =================================================================

-- Enable RLS on content_approval_requests table
ALTER TABLE content_approval_requests ENABLE ROW LEVEL SECURITY;

-- Users can view their own approval requests
CREATE POLICY content_approval_requests_select_own ON content_approval_requests
  FOR SELECT USING (submitter_id = auth.uid());

-- Users can create approval requests
CREATE POLICY content_approval_requests_insert_user ON content_approval_requests
  FOR INSERT WITH CHECK (submitter_id = auth.uid());

-- Admins and content managers can view and manage all approval requests
CREATE POLICY content_approval_requests_all_admin ON content_approval_requests
  FOR ALL USING (is_admin() OR has_permission('approve_content'));

-- Business owners can view approval requests for their businesses
CREATE POLICY content_approval_requests_select_business ON content_approval_requests
  FOR SELECT USING (
    content_type = 'business_profile' AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = content_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Enable RLS on content_change_history table
ALTER TABLE content_change_history ENABLE ROW LEVEL SECURITY;

-- Users can view change history for their own content
CREATE POLICY content_change_history_select_own ON content_change_history
  FOR SELECT USING (changed_by = auth.uid());

-- Admins can view and manage all change history
CREATE POLICY content_change_history_all_admin ON content_change_history
  FOR ALL USING (is_admin());

-- Business owners can view change history for their businesses
CREATE POLICY content_change_history_select_business ON content_change_history
  FOR SELECT USING (
    content_type = 'business_profile' AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = content_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- =================================================================
-- API INTEGRATION
-- =================================================================

-- Enable RLS on api_integrations table
ALTER TABLE api_integrations ENABLE ROW LEVEL SECURITY;

-- Only admins can view and manage API integrations
CREATE POLICY api_integrations_all_admin ON api_integrations
  FOR ALL USING (is_admin());

-- =================================================================
-- ANALYTICS & LOGGING
-- =================================================================

-- Enable RLS on page_views table
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;

-- Users can view their own page views
CREATE POLICY page_views_select_own ON page_views
  FOR SELECT USING (viewer_id = auth.uid());

-- Admins can view all page views
CREATE POLICY page_views_select_admin ON page_views
  FOR SELECT USING (is_admin());

-- Business owners can view page views for their businesses
CREATE POLICY page_views_select_business ON page_views
  FOR SELECT USING (
    view_type = 'business' AND
    EXISTS (
      SELECT 1 FROM businesses
      WHERE businesses.id = content_id
      AND businesses.owner_id = auth.uid()
    )
  );

-- Anyone can insert page views
CREATE POLICY page_views_insert_any ON page_views
  FOR INSERT WITH CHECK (true);

-- Enable RLS on system_logs table
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can view system logs
CREATE POLICY system_logs_select_admin ON system_logs
  FOR SELECT USING (is_admin());

-- Users can view their own logs
CREATE POLICY system_logs_select_own ON system_logs
  FOR SELECT USING (user_id = auth.uid());
