const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const companyController = require("./company.controller");

router.post("/", authMiddleware, companyController.create);
router.get("/", authMiddleware, companyController.getAll);
router.get("/:id", authMiddleware, companyController.getById);
router.put("/:id", authMiddleware, companyController.update);
router.delete("/:id", authMiddleware, companyController.delete);

module.exports = router;
