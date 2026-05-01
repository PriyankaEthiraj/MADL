export const ok = (res, data = {}, message = "success") =>
  res.json({ message, data });

export const created = (res, data = {}, message = "created") =>
  res.status(201).json({ message, data });
