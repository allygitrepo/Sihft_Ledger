const express = require("express");
const router = express.Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const userController = require("./user.controller");

router.post("/register", userController.register);
router.post("/login", userController.login);
router.put("/update-profile", authMiddleware, userController.updateProfile);

module.exports = router;