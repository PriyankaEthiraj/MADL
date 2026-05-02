import { Router } from "express";
import { 
  listDepartments, 
  createDepartment, 
  updateDepartment, 
  deleteDepartment 
} from "../controllers/departmentsController.js";
import { requireAuth, rbac } from "../middlewares/auth.js";

const router = Router();

router.use(requireAuth);
router.get("/", listDepartments);
router.post("/", rbac(["admin"]), createDepartment);
router.put("/:id", rbac(["admin"]), updateDepartment);
router.delete("/:id", rbac(["admin"]), deleteDepartment);

export default router;
