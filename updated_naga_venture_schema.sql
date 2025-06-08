-- NAGA VENTURE Database Schema for Supabase
-- Created: June 8, 2025 (Updated)
-- Description: Complete SQL schema for NAGA VENTURE tourism platform with critical fixes

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =================================================================
-- AUTHENTICATION & USER MANAGEMENT
-- =================================================================

-- User Roles Enum
CREATE TYPE user_role AS ENUM (
  'tourism_admin',
  'business_listing_manager',
  'tourism_content_manager',
  'business_registration_manager',
  'business_owner',
  'tourist'
);

-- Profiles Table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone_number TEXT,
  profile_image_url TEXT,
  role user_role NOT NULL DEFAULT 'tourist',
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE profiles IS 'User profiles for all system users, linked to Supabase auth';

-- CRITICAL FIX: Auth-Profile Trigger
-- This function runs automatically when a new user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- This trigger connects the function to the auth system
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- Staff Permissions Table (for admin and manager roles)
CREATE TABLE staff_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  can_manage_users BOOLEAN NOT NULL DEFAULT FALSE,
  can_manage_businesses BOOLEAN NOT NULL DEFAULT FALSE,
  can_manage_tourist_spots BOOLEAN NOT NULL DEFAULT FALSE,
  can_manage_events BOOLEAN NOT NULL DEFAULT FALSE,
  can_approve_content BOOLEAN NOT NULL DEFAULT FALSE,
  can_manage_categories BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE staff_permissions IS 'Detailed permissions for staff members (admins and managers)';

-- =================================================================
-- CATEGORIES
-- =================================================================

-- Main Categories Table
CREATE TABLE main_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

COMMENT ON TABLE main_categories IS 'Main categories for businesses and tourist spots';

-- Sub Categories Table
CREATE TABLE sub_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  main_category_id UUID NOT NULL REFERENCES main_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  UNIQUE(main_category_id, name)
);

COMMENT ON TABLE sub_categories IS 'Sub-categories that belong to main categories';

-- =================================================================
-- BUSINESS LISTINGS
-- =================================================================

-- Business Types Enum
CREATE TYPE business_type AS ENUM (
  'accommodation',
  'shop',
  'service'
);

-- Business Status Enum
CREATE TYPE business_status AS ENUM (
  'pending',
  'approved',
  'rejected',
  'inactive'
);

-- Businesses Table
CREATE TABLE businesses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  business_name TEXT NOT NULL,
  business_type business_type NOT NULL,
  description TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'Naga City',
  province TEXT NOT NULL DEFAULT 'Camarines Sur',
  postal_code TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  facebook_url TEXT,
  instagram_url TEXT,
  twitter_url TEXT,
  location GEOGRAPHY(POINT) NOT NULL,
  google_maps_place_id TEXT,
  status business_status NOT NULL DEFAULT 'pending',
  is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  average_rating NUMERIC(3,2),
  review_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  rejection_reason TEXT,
  CONSTRAINT description_min_length CHECK (LENGTH(description) >= 200)
);

CREATE INDEX idx_businesses_location ON businesses USING GIST (location);
CREATE INDEX idx_businesses_business_type ON businesses (business_type);
CREATE INDEX idx_businesses_status ON businesses (status);

COMMENT ON TABLE businesses IS 'All business listings including accommodations, shops, and services';
COMMENT ON COLUMN businesses.location IS 'Geographic point location. Insert using ST_Point(longitude, latitude)';

-- Business Categories Junction Table
CREATE TABLE business_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  sub_category_id UUID NOT NULL REFERENCES sub_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, sub_category_id)
);

COMMENT ON TABLE business_categories IS 'Junction table linking businesses to their categories';

-- Business Images Table
CREATE TABLE business_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_business_images_business_id ON business_images (business_id);

COMMENT ON TABLE business_images IS 'Images for business listings (up to 10 per business)';

-- Business Hours Table
CREATE TABLE business_hours (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  open_time TIME,
  close_time TIME,
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, day_of_week)
);

COMMENT ON TABLE business_hours IS 'Operating hours for businesses';

-- Business Amenities Table
CREATE TABLE amenities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  icon_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE amenities IS 'List of possible amenities for businesses';

-- Business Amenities Junction Table
CREATE TABLE business_amenities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  amenity_id UUID NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, amenity_id)
);

COMMENT ON TABLE business_amenities IS 'Junction table linking businesses to their amenities';

-- =================================================================
-- ACCOMMODATION-SPECIFIC TABLES
-- =================================================================

-- Room Types Table
CREATE TABLE room_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  capacity INTEGER NOT NULL,
  price_per_night NUMERIC(10,2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT business_is_accommodation CHECK (
    EXISTS (
      SELECT 1 FROM businesses 
      WHERE businesses.id = business_id 
      AND businesses.business_type = 'accommodation'
    )
  )
);

CREATE INDEX idx_room_types_business_id ON room_types (business_id);

COMMENT ON TABLE room_types IS 'Room types available for accommodation businesses';

-- Room Images Table
CREATE TABLE room_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_type_id UUID NOT NULL REFERENCES room_types(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_room_images_room_type_id ON room_images (room_type_id);

COMMENT ON TABLE room_images IS 'Images for specific room types';

-- Room Amenities Junction Table
CREATE TABLE room_amenities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_type_id UUID NOT NULL REFERENCES room_types(id) ON DELETE CASCADE,
  amenity_id UUID NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(room_type_id, amenity_id)
);

COMMENT ON TABLE room_amenities IS 'Junction table linking room types to their amenities';

-- =================================================================
-- BOOKING SYSTEM
-- =================================================================

-- Booking Status Enum
CREATE TYPE booking_status AS ENUM (
  'pending',
  'confirmed',
  'cancelled',
  'completed',
  'no_show'
);

-- Payment Status Enum
CREATE TYPE payment_status AS ENUM (
  'pending',
  'paid',
  'failed',
  'refunded',
  'partially_refunded'
);

-- Payment Method Enum
CREATE TYPE payment_method AS ENUM (
  'gcash',
  'paypal',
  'xendit',
  'credit_card',
  'cash'
);

-- Bookings Table
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_number TEXT NOT NULL UNIQUE,
  guest_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  room_type_id UUID REFERENCES room_types(id) ON DELETE SET NULL,
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  number_of_guests INTEGER NOT NULL,
  special_requests TEXT,
  total_amount NUMERIC(10,2) NOT NULL,
  status booking_status NOT NULL DEFAULT 'pending',
  payment_status payment_status NOT NULL DEFAULT 'pending',
  payment_method payment_method,
  payment_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_date_range CHECK (check_out_date > check_in_date),
  CONSTRAINT business_is_accommodation CHECK (
    EXISTS (
      SELECT 1 FROM businesses 
      WHERE businesses.id = business_id 
      AND businesses.business_type = 'accommodation'
    )
  )
);

CREATE INDEX idx_bookings_guest_id ON bookings (guest_id);
CREATE INDEX idx_bookings_business_id ON bookings (business_id);
CREATE INDEX idx_bookings_date_range ON bookings (check_in_date, check_out_date);
CREATE INDEX idx_bookings_status ON bookings (status);

COMMENT ON TABLE bookings IS 'Accommodation bookings made through the platform';

-- Payment Transactions Table
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  payment_method payment_method NOT NULL,
  transaction_id TEXT,
  payment_status payment_status NOT NULL,
  payment_gateway TEXT NOT NULL,
  gateway_response JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_booking_id ON payment_transactions (booking_id);

COMMENT ON TABLE payment_transactions IS 'Payment transaction records for bookings';

-- =================================================================
-- TOURIST SPOTS
-- =================================================================

-- Tourist Spot Status Enum
CREATE TYPE tourist_spot_status AS ENUM (
  'active',
  'inactive',
  'under_maintenance',
  'coming_soon'
);

-- Tourist Spot Type Enum
CREATE TYPE tourist_spot_type AS ENUM (
  'natural',
  'cultural',
  'historical',
  'religious',
  'recreational',
  'other'
);

-- Tourist Spots Table
CREATE TABLE tourist_spots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  spot_type tourist_spot_type NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'Naga City',
  province TEXT NOT NULL DEFAULT 'Camarines Sur',
  location GEOGRAPHY(POINT) NOT NULL,
  google_maps_place_id TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  website TEXT,
  opening_time TIME,
  closing_time TIME,
  entry_fee NUMERIC(10,2),
  status tourist_spot_status NOT NULL DEFAULT 'active',
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  average_rating NUMERIC(3,2),
  review_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

CREATE INDEX idx_tourist_spots_location ON tourist_spots USING GIST (location);
CREATE INDEX idx_tourist_spots_status ON tourist_spots (status);
CREATE INDEX idx_tourist_spots_type ON tourist_spots (spot_type);

COMMENT ON TABLE tourist_spots IS 'Tourist attractions and points of interest';
COMMENT ON COLUMN tourist_spots.location IS 'Geographic point location. Insert using ST_Point(longitude, latitude)';

-- Tourist Spot Categories Junction Table
CREATE TABLE tourist_spot_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tourist_spot_id UUID NOT NULL REFERENCES tourist_spots(id) ON DELETE CASCADE,
  sub_category_id UUID NOT NULL REFERENCES sub_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tourist_spot_id, sub_category_id)
);

COMMENT ON TABLE tourist_spot_categories IS 'Junction table linking tourist spots to their categories';

-- Tourist Spot Images Table
CREATE TABLE tourist_spot_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tourist_spot_id UUID NOT NULL REFERENCES tourist_spots(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tourist_spot_images_spot_id ON tourist_spot_images (tourist_spot_id);

COMMENT ON TABLE tourist_spot_images IS 'Images for tourist spots';

-- =================================================================
-- EVENTS
-- =================================================================

-- Event Status Enum
CREATE TYPE event_status AS ENUM (
  'upcoming',
  'ongoing',
  'completed',
  'cancelled'
);

-- Events Table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  venue_name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'Naga City',
  province TEXT NOT NULL DEFAULT 'Camarines Sur',
  location GEOGRAPHY(POINT) NOT NULL,
  tourist_spot_id UUID REFERENCES tourist_spots(id) ON DELETE SET NULL,
  business_id UUID REFERENCES businesses(id) ON DELETE SET NULL,
  entry_fee NUMERIC(10,2),
  organizer_name TEXT,
  organizer_contact TEXT,
  organizer_email TEXT,
  website TEXT,
  status event_status NOT NULL DEFAULT 'upcoming',
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  average_rating NUMERIC(3,2),
  review_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

CREATE INDEX idx_events_location ON events USING GIST (location);
CREATE INDEX idx_events_date_range ON events (start_date, end_date);
CREATE INDEX idx_events_status ON events (status);

COMMENT ON TABLE events IS 'Events and activities happening in Naga City';
COMMENT ON COLUMN events.location IS 'Geographic point location. Insert using ST_Point(longitude, latitude)';

-- Event Categories Junction Table
CREATE TABLE event_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  sub_category_id UUID NOT NULL REFERENCES sub_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(event_id, sub_category_id)
);

COMMENT ON TABLE event_categories IS 'Junction table linking events to their categories';

-- Event Images Table
CREATE TABLE event_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_images_event_id ON event_images (event_id);

COMMENT ON TABLE event_images IS 'Images for events';

-- =================================================================
-- REVIEWS & RATINGS
-- =================================================================

-- Review Type Enum
CREATE TYPE review_type AS ENUM (
  'business',
  'tourist_spot',
  'event'
);

-- Reviews Table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  review_type review_type NOT NULL,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  tourist_spot_id UUID REFERENCES tourist_spots(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  is_approved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT one_entity_only CHECK (
    (business_id IS NOT NULL AND tourist_spot_id IS NULL AND event_id IS NULL) OR
    (business_id IS NULL AND tourist_spot_id IS NOT NULL AND event_id IS NULL) OR
    (business_id IS NULL AND tourist_spot_id IS NULL AND event_id IS NOT NULL)
  ),
  CONSTRAINT matching_review_type CHECK (
    (review_type = 'business' AND business_id IS NOT NULL) OR
    (review_type = 'tourist_spot' AND tourist_spot_id IS NOT NULL) OR
    (review_type = 'event' AND event_id IS NOT NULL)
  )
);

CREATE INDEX idx_reviews_reviewer_id ON reviews (reviewer_id);
CREATE INDEX idx_reviews_business_id ON reviews (business_id) WHERE business_id IS NOT NULL;
CREATE INDEX idx_reviews_tourist_spot_id ON reviews (tourist_spot_id) WHERE tourist_spot_id IS NOT NULL;
CREATE INDEX idx_reviews_event_id ON reviews (event_id) WHERE event_id IS NOT NULL;

COMMENT ON TABLE reviews IS 'User reviews and ratings for businesses, tourist spots, and events';

-- Review Responses Table
CREATE TABLE review_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  responder_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  response TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_responses_review_id ON review_responses (review_id);

COMMENT ON TABLE review_responses IS 'Responses from business owners or admins to user reviews';

-- Review Images Table
CREATE TABLE review_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_images_review_id ON review_images (review_id);

COMMENT ON TABLE review_images IS 'Images attached to user reviews';

-- =================================================================
-- PROMOTIONS & SPECIAL OFFERS
-- =================================================================

-- Promotion Status Enum
CREATE TYPE promotion_status AS ENUM (
  'active',
  'scheduled',
  'expired',
  'cancelled'
);

-- Promotions Table
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  is_platform_wide BOOLEAN NOT NULL DEFAULT FALSE,
  discount_percentage INTEGER,
  discount_amount NUMERIC(10,2),
  promo_code TEXT,
  terms_conditions TEXT,
  status promotion_status NOT NULL DEFAULT 'scheduled',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  CONSTRAINT valid_date_range CHECK (end_date >= start_date),
  CONSTRAINT business_or_platform CHECK (
    (business_id IS NOT NULL AND is_platform_wide = FALSE) OR
    (business_id IS NULL AND is_platform_wide = TRUE)
  )
);

CREATE INDEX idx_promotions_date_range ON promotions (start_date, end_date);
CREATE INDEX idx_promotions_business_id ON promotions (business_id) WHERE business_id IS NOT NULL;
CREATE INDEX idx_promotions_status ON promotions (status);

COMMENT ON TABLE promotions IS 'Promotions and special offers from businesses or platform-wide';

-- Promotion Images Table
CREATE TABLE promotion_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_promotion_images_promotion_id ON promotion_images (promotion_id);

COMMENT ON TABLE promotion_images IS 'Images for promotions and special offers';

-- =================================================================
-- CONTENT APPROVAL WORKFLOW
-- =================================================================

-- Content Type Enum
CREATE TYPE content_type AS ENUM (
  'business_profile',
  'tourist_spot',
  'event',
  'promotion'
);

-- Content Status Enum
CREATE TYPE content_status AS ENUM (
  'pending',
  'approved',
  'rejected'
);

-- Content Approval Requests Table
CREATE TABLE content_approval_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content_type content_type NOT NULL,
  content_id UUID NOT NULL,
  submitter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status content_status NOT NULL DEFAULT 'pending',
  submission_notes TEXT,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

CREATE INDEX idx_content_approval_requests_content ON content_approval_requests (content_type, content_id);
CREATE INDEX idx_content_approval_requests_submitter ON content_approval_requests (submitter_id);
CREATE INDEX idx_content_approval_requests_status ON content_approval_requests (status);

COMMENT ON TABLE content_approval_requests IS 'Requests for content approval in the workflow';

-- Content Change History Table
CREATE TABLE content_change_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content_type content_type NOT NULL,
  content_id UUID NOT NULL,
  changed_by UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
  previous_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_content_change_history_content ON content_change_history (content_type, content_id);

COMMENT ON TABLE content_change_history IS 'History of changes made to content for auditing purposes';

-- =================================================================
-- API INTEGRATION
-- =================================================================

-- API Integration Table
CREATE TABLE api_integrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  api_key TEXT,
  api_secret TEXT,
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

COMMENT ON TABLE api_integrations IS 'Configuration for external API integrations';

-- =================================================================
-- ANALYTICS & LOGGING
-- =================================================================

-- Page View Types Enum
CREATE TYPE page_view_type AS ENUM (
  'business',
  'tourist_spot',
  'event',
  'promotion'
);

-- Page Views Table
CREATE TABLE page_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  view_type page_view_type NOT NULL,
  content_id UUID NOT NULL,
  viewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ip_address TEXT,
  user_agent TEXT,
  referrer TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_page_views_content ON page_views (view_type, content_id);
CREATE INDEX idx_page_views_viewer ON page_views (viewer_id) WHERE viewer_id IS NOT NULL;
CREATE INDEX idx_page_views_created_at ON page_views (created_at);

COMMENT ON TABLE page_views IS 'Analytics for page views of different content types';

-- System Logs Table
CREATE TABLE system_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ip_address TEXT,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_system_logs_action ON system_logs (action);
CREATE INDEX idx_system_logs_entity ON system_logs (entity_type, entity_id) WHERE entity_type IS NOT NULL;
CREATE INDEX idx_system_logs_user_id ON system_logs (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_system_logs_created_at ON system_logs (created_at);

COMMENT ON TABLE system_logs IS 'System-wide logging for auditing and debugging';

-- =================================================================
-- ROW LEVEL SECURITY POLICIES
-- =================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE main_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE sub_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE amenities ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_amenities ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_amenities ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tourist_spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE tourist_spot_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tourist_spot_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_approval_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_change_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (to be expanded based on specific requirements)

-- Profiles: Users can read all profiles but only update their own
CREATE POLICY profiles_select_all ON profiles FOR SELECT USING (true);
CREATE POLICY profiles_update_own ON profiles FOR UPDATE USING (auth.uid() = id);

-- Businesses: Public can view approved businesses, owners can manage their own
CREATE POLICY businesses_select_public ON businesses FOR SELECT USING (status = 'approved');
CREATE POLICY businesses_manage_own ON businesses FOR ALL USING (owner_id = auth.uid());
CREATE POLICY businesses_manage_admin ON businesses FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND (profiles.role = 'tourism_admin' OR profiles.role = 'business_listing_manager')
  )
);

-- Bookings: Guests can see their own bookings, business owners can see bookings for their business
CREATE POLICY bookings_select_guest ON bookings FOR SELECT USING (guest_id = auth.uid());
CREATE POLICY bookings_select_business ON bookings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM businesses 
    WHERE businesses.id = business_id 
    AND businesses.owner_id = auth.uid()
  )
);
CREATE POLICY bookings_select_admin ON bookings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'tourism_admin'
  )
);

-- Reviews: Public can view approved reviews, users can manage their own
CREATE POLICY reviews_select_public ON reviews FOR SELECT USING (is_approved = true);
CREATE POLICY reviews_manage_own ON reviews FOR ALL USING (reviewer_id = auth.uid());
CREATE POLICY reviews_manage_admin ON reviews FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'tourism_admin'
  )
);

-- =================================================================
-- FUNCTIONS & TRIGGERS
-- =================================================================

-- Function to update average rating for businesses
CREATE OR REPLACE FUNCTION update_business_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.review_type = 'business' AND NEW.business_id IS NOT NULL THEN
    UPDATE businesses
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE business_id = NEW.business_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE business_id = NEW.business_id
        AND is_approved = true
      )
    WHERE id = NEW.business_id;
  ELSIF TG_OP = 'DELETE' AND OLD.review_type = 'business' AND OLD.business_id IS NOT NULL THEN
    UPDATE businesses
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE business_id = OLD.business_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE business_id = OLD.business_id
        AND is_approved = true
      )
    WHERE id = OLD.business_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for business rating updates
CREATE TRIGGER update_business_rating_trigger
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_business_rating();

-- Function to update average rating for tourist spots
CREATE OR REPLACE FUNCTION update_tourist_spot_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.review_type = 'tourist_spot' AND NEW.tourist_spot_id IS NOT NULL THEN
    UPDATE tourist_spots
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE tourist_spot_id = NEW.tourist_spot_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE tourist_spot_id = NEW.tourist_spot_id
        AND is_approved = true
      )
    WHERE id = NEW.tourist_spot_id;
  ELSIF TG_OP = 'DELETE' AND OLD.review_type = 'tourist_spot' AND OLD.tourist_spot_id IS NOT NULL THEN
    UPDATE tourist_spots
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE tourist_spot_id = OLD.tourist_spot_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE tourist_spot_id = OLD.tourist_spot_id
        AND is_approved = true
      )
    WHERE id = OLD.tourist_spot_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for tourist spot rating updates
CREATE TRIGGER update_tourist_spot_rating_trigger
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_tourist_spot_rating();

-- Function to update average rating for events
CREATE OR REPLACE FUNCTION update_event_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.review_type = 'event' AND NEW.event_id IS NOT NULL THEN
    UPDATE events
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE event_id = NEW.event_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE event_id = NEW.event_id
        AND is_approved = true
      )
    WHERE id = NEW.event_id;
  ELSIF TG_OP = 'DELETE' AND OLD.review_type = 'event' AND OLD.event_id IS NOT NULL THEN
    UPDATE events
    SET 
      average_rating = (
        SELECT AVG(rating)::numeric(3,2)
        FROM reviews
        WHERE event_id = OLD.event_id
        AND is_approved = true
      ),
      review_count = (
        SELECT COUNT(*)
        FROM reviews
        WHERE event_id = OLD.event_id
        AND is_approved = true
      )
    WHERE id = OLD.event_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for event rating updates
CREATE TRIGGER update_event_rating_trigger
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_event_rating();

-- Function to update promotion status based on dates
CREATE OR REPLACE FUNCTION update_promotion_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.start_date <= CURRENT_DATE AND NEW.end_date >= CURRENT_DATE THEN
    NEW.status := 'active';
  ELSIF NEW.start_date > CURRENT_DATE THEN
    NEW.status := 'scheduled';
  ELSIF NEW.end_date < CURRENT_DATE THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for promotion status updates
CREATE TRIGGER update_promotion_status_trigger
BEFORE INSERT OR UPDATE ON promotions
FOR EACH ROW
EXECUTE FUNCTION update_promotion_status();

-- Function to generate booking number
CREATE OR REPLACE FUNCTION generate_booking_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.booking_number := 'BK-' || to_char(NOW(), 'YYYYMMDD') || '-' || 
                        LPAD(CAST(floor(random() * 10000) AS TEXT), 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for booking number generation
CREATE TRIGGER generate_booking_number_trigger
BEFORE INSERT ON bookings
FOR EACH ROW
EXECUTE FUNCTION generate_booking_number();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_timestamp trigger to all tables with updated_at column
CREATE TRIGGER update_timestamp_trigger
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Add similar triggers for all other tables with updated_at column
