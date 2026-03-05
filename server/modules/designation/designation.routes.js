const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const designationController = require("./designation.controller");

router.post("/", authMiddleware, designationController.create);
router.get("/", authMiddleware, designationController.getAll);
router.get("/:id", authMiddleware, designationController.getById);
router.put("/:id", authMiddleware, designationController.update);
router.delete("/:id", authMiddleware, designationController.delete);

module.exports = router;
