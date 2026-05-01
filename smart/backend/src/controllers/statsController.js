import { fetchStats } from "../services/complaintService.js";
import { ok } from "../utils/responses.js";

export const getStats = async (_req, res, next) => {
  try {
    const stats = await fetchStats();
    return ok(res, stats, "stats");
  } catch (err) {
    return next(err);
  }
};
