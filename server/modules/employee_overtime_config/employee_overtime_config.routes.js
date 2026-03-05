const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const employeeOvertimeConfigController = require("./employee_overtime_config.controller");

router.post("/", authMiddleware, employeeOvertimeConfigController.createOrUpdate);
router.get("/employee/:employee_id", authMiddleware, employeeOvertimeConfigController.getByEmployeeId);
router.delete("/:id", authMiddleware, employeeOvertimeConfigController.delete);

module.exports = router;
