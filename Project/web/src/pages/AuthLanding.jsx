import React from 'react';
import { Link } from 'react-router-dom';
import '../styles/auth.css';

/**
 * AuthLanding Component
 * 
 * Landing page for Smart City Complaint Management System
 * Provides separate entry points for Admin and Department users
 * 
 * Features:
 * - Modern, enterprise-grade design
 * - Separate entry icons for Admin and Department
 * - Smooth animations and hover effects
 * - Fully responsive layout
 */

const AuthLanding = () => {
  return (
    <div className="auth-page">
      <div className="auth-container">
        <div className="landing-container">
          {/* Header Section */}
          <div className="landing-header">
            <div className="landing-logo">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <path d="M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V7.89l7-3.11v8.2z"/>
              </svg>
            </div>
            <h1 className="landing-title">Smart City Portal</h1>
          </div>

          {/* Entry Options */}
          <div className="entry-options">
            {/* Admin Entry */}
            <Link to="/admin/login" className="entry-card">
              <div className="entry-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/>
                </svg>
              </div>
              <h2 className="entry-title">Admin Portal</h2>
            </Link>

            {/* Department Entry */}
            <Link to="/department/login" className="entry-card">
              <div className="entry-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="M12 7V3H2v18h20V7H12zM6 19H4v-2h2v2zm0-4H4v-2h2v2zm0-4H4V9h2v2zm0-4H4V5h2v2zm4 12H8v-2h2v2zm0-4H8v-2h2v2zm0-4H8V9h2v2zm0-4H8V5h2v2zm10 12h-8v-2h2v-2h-2v-2h2v-2h-2V9h8v10zm-2-8h-2v2h2v-2zm0 4h-2v2h2v-2z"/>
                </svg>
              </div>
              <h2 className="entry-title">Department Portal</h2>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuthLanding;
