import { 
  fetchDepartments, 
  createDept, 
  updateDept, 
  deleteDept 
} from "../services/departmentService.js";
import { ok, created } from "../utils/responses.js";
import { badRequest } from "../utils/errors.js";

export const listDepartments = async (_req, res, next) => {
  try {
    const departments = await fetchDepartments();
    return ok(res, departments, "departments");
  } catch (err) {
    return next(err);
  }
};

export const createDepartment = async (req, res, next) => {
  try {
    const { name, type } = req.body;
    if (!name) throw badRequest("Department name is required");
    
    const department = await createDept({ name, type });
    return created(res, department, "Department created successfully");
  } catch (err) {
    return next(err);
  }
};

export const updateDepartment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, type } = req.body;
    
    const department = await updateDept(Number(id), { name, type });
    return ok(res, department, "Department updated successfully");
  } catch (err) {
    return next(err);
  }
};

export const deleteDepartment = async (req, res, next) => {
  try {
    const { id } = req.params;
    await deleteDept(Number(id));
    return ok(res, null, "Department deleted successfully");
  } catch (err) {
    return next(err);
  }
};
