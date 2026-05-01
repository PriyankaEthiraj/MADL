export class ApiError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export const notFound = (message = "Not found") =>
  new ApiError(404, message);

export const badRequest = (message = "Bad request", details) =>
  new ApiError(400, message, details);

export const unauthorized = (message = "Unauthorized") =>
  new ApiError(401, message);

export const forbidden = (message = "Forbidden") =>
  new ApiError(403, message);
