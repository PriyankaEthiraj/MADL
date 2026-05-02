import { register, login, updateProfile } from "../services/authService.js";
import { created, ok } from "../utils/responses.js";

export const registerUser = async (req, res, next) => {
  try {
    const result = await register(req.body);
    return created(res, result, "registered");
  } catch (err) {
    return next(err);
  }
};

export const loginUser = async (req, res, next) => {
  try {
    const result = await login(req.body);
    return ok(res, result, "authenticated");
  } catch (err) {
    return next(err);
  }
};

export const getCurrentUser = async (req, res, next) => {
  try {
    return ok(res, req.user, "current user");
  } catch (err) {
    return next(err);
  }
};

export const updateUserProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const updatedUser = await updateProfile(userId, req.body);
    return ok(res, updatedUser, "profile updated");
  } catch (err) {
    return next(err);
  }
};
