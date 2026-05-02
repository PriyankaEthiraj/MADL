export const errorHandler = (err, _req, res, _next) => {
  const status = err.status || 500;
  const message = err.message || "Internal server error";
  const details = err.details;
  
  // Log full error to console for debugging
  if (status === 500) {
    console.error("[500 ERROR]", err.message);
    console.error("[STACK]", err.stack);
    if (err.code) console.error("[DB CODE]", err.code);
  }
  
  res.status(status).json({ message, details });
};
