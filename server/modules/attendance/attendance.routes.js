const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const attendanceController = require("./attendance.controller");

router.post("/clock-in", authMiddleware, attendanceController.clockIn);
router.post("/clock-out", authMiddleware, attendanceController.clockOut);
router.get("/employee/:employee_id", authMiddleware, attendanceController.getByEmployee);
router.put("/status/:id", authMiddleware, attendanceController.updateStatus);

module.exports = router;
