import { verifyToken } from "../utils/jwt.js";
import { unauthorized } from "../utils/errors.js";

export const requireAuth = (req, _res, next) => {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return next(unauthorized("Missing token"));
  }
  try {
    req.user = verifyToken(token);
    return next();
  } catch (err) {
    return next(unauthorized("Invalid token"));
  }
};

export const rbac = (allowedRoles) => {
  return (req, _res, next) => {
    if (!req.user) {
      return next(unauthorized("Not authenticated"));
    }
    if (!allowedRoles.includes(req.user.role)) {
      return next(unauthorized("Insufficient permissions"));
    }
    return next();
  };
};
