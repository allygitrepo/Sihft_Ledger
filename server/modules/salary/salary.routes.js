const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const salaryController = require("./salary.controller");

router.post("/generate", authMiddleware, salaryController.generateSalary);
router.get("/", authMiddleware, salaryController.getSalariesByMonth);
router.get("/history/:employee_id", authMiddleware, salaryController.getEmployeeSalaryHistory);
router.put("/pay/:id", authMiddleware, salaryController.markAsPaid);

module.exports = router;
