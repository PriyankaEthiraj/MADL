-- Migration: Add video and geotag support to complaints
-- This migration adds video URL and geolocation metadata fields to the complaints table

ALTER TABLE complaints
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS photo_latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS photo_longitude DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS photo_timestamp TIMESTAMP,
ADD COLUMN IF NOT EXISTS photo_location_name TEXT,
ADD COLUMN IF NOT EXISTS video_latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS video_longitude DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS video_timestamp TIMESTAMP,
ADD COLUMN IF NOT EXISTS video_location_name TEXT;

-- Create index for faster geolocation queries
CREATE INDEX IF NOT EXISTS idx_complaints_photo_location 
ON complaints(photo_latitude, photo_longitude);

CREATE INDEX IF NOT EXISTS idx_complaints_video_location 
ON complaints(video_latitude, video_longitude);
