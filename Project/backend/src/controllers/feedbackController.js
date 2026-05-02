import { fetchFeedback } from "../services/complaintService.js";
import { ok } from "../utils/responses.js";

export const listFeedback = async (_req, res, next) => {
  try {
    const feedback = await fetchFeedback();
    return ok(res, feedback, "feedback");
  } catch (err) {
    return next(err);
  }
};
