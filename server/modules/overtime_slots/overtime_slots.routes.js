const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const overtimeSlotController = require("./overtime_slots.controller");

router.post("/", authMiddleware, overtimeSlotController.create);
router.get("/", authMiddleware, overtimeSlotController.getAll);
router.get("/:id", authMiddleware, overtimeSlotController.getById);
router.put("/:id", authMiddleware, overtimeSlotController.update);
router.delete("/:id", authMiddleware, overtimeSlotController.delete);

module.exports = router;
