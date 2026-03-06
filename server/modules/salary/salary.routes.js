const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const salaryController = require("./salary.controller");

router.post("/", authMiddleware, salaryController.saveConfig);
router.get("/company/:company_id", authMiddleware, salaryController.getConfig);

module.exports = router;
