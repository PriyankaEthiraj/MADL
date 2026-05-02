import { createContext, useContext, useEffect, useState } from "react";
import { api } from "../services/api.js";

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Initialize auth state from localStorage
    const storedToken = localStorage.getItem("token");
    const storedUser = localStorage.getItem("user");
    
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
    
    setLoading(false);
  }, []);

  const login = async (identifier, password) => {
    const trimmed = identifier.trim();
    let body;

    if (trimmed.includes("@")) {
      body = { email: trimmed, password };
    } else if (/^\d+$/.test(trimmed)) {
      body = { phone: trimmed, password };
    } else {
      throw new Error("Enter a valid email address");
    }

    const { data } = await api.post("/auth/login", body);
    const payload = data.data;
    setUser(payload.user);
    setToken(payload.token);
    localStorage.setItem("token", payload.token);
    localStorage.setItem("user", JSON.stringify(payload.user));
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem("token");
    localStorage.removeItem("user");
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
