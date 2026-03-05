const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const employeeController = require("./employee.controller");

router.post("/", authMiddleware, employeeController.create);
router.get("/", authMiddleware, employeeController.getAll);
router.get("/:id", authMiddleware, employeeController.getById);
router.put("/:id", authMiddleware, employeeController.update);
router.delete("/:id", authMiddleware, employeeController.delete);

module.exports = router;
