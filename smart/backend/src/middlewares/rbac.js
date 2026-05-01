import { forbidden } from "../utils/errors.js";

export const requireRole = (...roles) => (req, _res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(forbidden("Insufficient permissions"));
  }
  return next();
};
