const express = require("express");
const router = express.Router();
const userRoutes = require("./user/user.routes");
const companyRoutes = require("./company/company.routes");
const departmentRoutes = require("./department/department.routes");
const designationRoutes = require("./designation/designation.routes");
const employeeRoutes = require("./employee/employee.routes");
const attendanceRoutes = require("./attendance/attendance.routes");
const salaryRoutes = require("./salary/salary.routes");
const employeeSalaryRoutes = require("./employee_salary/employee_salary.routes");
const overtimeSlotsRoutes = require("./overtime_slots/overtime_slots.routes");
const employeeOvertimeConfigRoutes = require("./employee_overtime_config/employee_overtime_config.routes");

router.use("/user", userRoutes);
router.use("/companies", companyRoutes);
router.use("/departments", departmentRoutes);
router.use("/designations", designationRoutes);
router.use("/employees", employeeRoutes);
router.use("/attendance", attendanceRoutes);
router.use("/salaries", salaryRoutes);
router.use("/employee-salaries", employeeSalaryRoutes);
router.use("/overtime-slots", overtimeSlotsRoutes);
router.use("/employee-overtime-configs", employeeOvertimeConfigRoutes);

module.exports = router;