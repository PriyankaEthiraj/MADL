import { badRequest } from "../utils/errors.js";

export const validateBody = (schema) => (req, _res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    return next(badRequest("Validation error", result.error.flatten()));
  }
  req.body = result.data;
  return next();
};
