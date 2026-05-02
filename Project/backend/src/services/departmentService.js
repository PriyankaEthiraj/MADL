import { 
  listDepartments,
  addDepartment,
  updateDepartmentById,
  removeDepartment
} from "../models/departmentsModel.js";

export const fetchDepartments = async () => listDepartments();

export const createDept = async (data) => addDepartment(data);

export const updateDept = async (id, data) => updateDepartmentById(id, data);

export const deleteDept = async (id) => removeDepartment(id);
