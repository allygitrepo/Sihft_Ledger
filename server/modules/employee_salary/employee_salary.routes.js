const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const employeeSalaryController = require("./employee_salary.controller");

router.post("/", authMiddleware, employeeSalaryController.create);
router.get("/", authMiddleware, employeeSalaryController.getAll);
router.get("/employee/:emp_id", authMiddleware, employeeSalaryController.getByEmployeeId);
router.put("/:id", authMiddleware, employeeSalaryController.update);
router.delete("/:id", authMiddleware, employeeSalaryController.delete);

module.exports = router;
