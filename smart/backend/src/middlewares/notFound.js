import { notFound } from "../utils/errors.js";

export const notFoundHandler = (_req, _res, next) => {
  next(notFound("Route not found"));
};
