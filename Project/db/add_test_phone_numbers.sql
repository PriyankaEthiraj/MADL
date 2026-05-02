-- Add phone numbers to existing test users for mobile/web phone login testing

UPDATE users SET phone = '9876543210' WHERE email = 'citi@gmail.com';
UPDATE users SET phone = '8888811111' WHERE email = 'citi2@gmail.com';
UPDATE users SET phone = '7777722222' WHERE email = 'citizen@gmail.com';
UPDATE users SET phone = '9999911111' WHERE email = 'test@gmail.com';

-- Verify the updates
SELECT id, name, email, phone FROM users WHERE phone IS NOT NULL;
