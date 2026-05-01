import { createUser, findUserByEmail, findUserByPhone, updateUser, updateUserPassword } from "../models/usersModel.js";
import { addDepartment, findDepartmentByName } from "../models/departmentsModel.js";
import { hashPassword, comparePassword } from "../utils/password.js";
import { signToken } from "../utils/jwt.js";
import { badRequest, unauthorized } from "../utils/errors.js";

export const register = async ({ name, email, password, role, departmentId, department_name, department_type, phone }) => {
  const normalizedEmail = email.trim().toLowerCase();
  const existing = await findUserByEmail(normalizedEmail);
  if (existing) {
    throw badRequest("Email already exists");
  }

  const normalizedPhone = phone ? phone.replace(/\D/g, "") : null;

  // Check if phone already exists (for citizens)
  if (normalizedPhone && role === "citizen") {
    const phoneExists = await findUserByPhone(normalizedPhone);
    if (phoneExists) {
      throw badRequest("Phone number already registered");
    }
  }
  
  const hashed = await hashPassword(password);
  let deptId = departmentId || null;
  
  // If registering as department, find existing department by type
  if (role === "department" && department_type) {
    const existingDept = await findDepartmentByName(department_type);
    if (existingDept) {
      deptId = existingDept.id;
    } else {
      const dept = await addDepartment({ 
        name: department_type, 
        type: department_type 
      });
      deptId = dept.id;
    }
  }
  
  const user = await createUser({
    name,
    email: normalizedEmail,
    password: hashed,
    role,
    departmentId: deptId,
    phone: normalizedPhone
  });
  const token = signToken({
    id: user.id,
    role: user.role,
    departmentId: user.department_id
  });
  return { user, token };
};

export const login = async ({ email, phone, password }) => {
  let user;
  
  // Login with email
  if (email) {
    user = await findUserByEmail(email.trim().toLowerCase());
  }
  // Login with phone
  else if (phone) {
    const normalizedPhone = phone.replace(/\D/g, "");
    user = await findUserByPhone(normalizedPhone);
  }
  
  if (!user) {
    throw unauthorized("Invalid credentials");
  }
  let ok = await comparePassword(password, user.password);

  // Backward compatibility: support legacy plaintext records and upgrade them.
  if (!ok && user.password === password) {
    const upgradedHash = await hashPassword(password);
    await updateUserPassword(user.id, upgradedHash);
    ok = true;
  }

  if (!ok) {
    throw unauthorized("Invalid credentials");
  }
  const token = signToken({
    id: user.id,
    role: user.role,
    departmentId: user.department_id
  });
  const { password: _pass, ...safeUser } = user;
  return { user: safeUser, token };
};

export const updateProfile = async (userId, { name, email, phone }) => {
  if (!name || name.trim() === "") {
    throw badRequest("Name is required");
  }
  
  if (!email || !email.includes('@')) {
    throw badRequest("Valid email is required");
  }
  
  const normalizedPhone = phone ? phone.replace(/\D/g, "") : null;
  
  // Check if email is being used by another user
  const emailExists = await findUserByEmail(email.trim());
  if (emailExists && emailExists.id !== userId) {
    throw badRequest("Email already in use");
  }
  
  // Check if phone is being used by another user
  if (normalizedPhone) {
    const phoneExists = await findUserByPhone(normalizedPhone);
    if (phoneExists && phoneExists.id !== userId) {
      throw badRequest("Phone number already in use");
    }
  }
  
  const updatedUser = await updateUser(userId, { 
    name: name.trim(),
    email: email.trim(),
    phone: normalizedPhone 
  });
  
  if (!updatedUser) {
    throw badRequest("Failed to update profile");
  }
  
  return updatedUser;
};
