const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const departmentController = require("./department.controller");

router.post("/", authMiddleware, departmentController.create);
router.get("/", authMiddleware, departmentController.getAll);
router.get("/:id", authMiddleware, departmentController.getById);
router.put("/:id", authMiddleware, departmentController.update);
router.delete("/:id", authMiddleware, departmentController.delete);

module.exports = router;
