import dotenv from 'dotenv';
dotenv.config();

console.log('DATABASE_URL from process.env:', process.env.DATABASE_URL);
console.log('SERVER_URL from process.env:', process.env.SERVER_URL);
console.log('NODE_ENV:', process.env.NODE_ENV);
