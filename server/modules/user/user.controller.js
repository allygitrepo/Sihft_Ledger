const User = require("./user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const usercontroller = {
    // ============ Register ============

    register: async (req, res) => {
        try {
            console.time("Register Process");
            const { owner_name, phone, email, password } = req.body;

            if (!owner_name || !phone || !password) {
                return res.status(400).json({ message: "All fields are required" });
            }

            // Normalize email: empty strings should be null to avoid UNIQUE constraint conflicts
            const normalizedEmail = (email && email.trim() !== "") ? email.trim() : null;

            const userExists = await User.findOne({ where: { phone } });

            if (userExists) {
                return res.status(400).json({ message: "User with this phone number already exists" });
            }

            console.time("Bcrypt Hash");
            const hashPass = await bcrypt.hash(password, 10);
            console.timeEnd("Bcrypt Hash");

            console.time("User Create");
            const user = await User.create({
                owner_name,
                phone,
                email: normalizedEmail,
                password: hashPass
            });
            console.timeEnd("User Create");

            // Generate token specifically for immediate login after registration
            const token = jwt.sign(
                { id: user.id },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN }
            );

            console.timeEnd("Register Process");
            return res.status(201).json({
                message: "User registered successfully",
                user,
                token
            });
        } catch (error) {
            console.error("Register Error:", error);
            return res.status(500).json({
                message: "Internal server error",
                details: error.message
            });
        }
    },

    // ============ Login ============

    login: async (req, res) => {
        try {
            const { phone, password } = req.body;

            if (!phone || !password) {
                return res.status(400).json({ message: "All fields are required" });
            }

            const user = await User.findOne({ where: { phone } });

            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }

            const isMatch = await bcrypt.compare(password, user.password);

            if (!isMatch) {
                return res.status(401).json({ message: "Invalid credentials" });
            }

            const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

            return res.status(200).json({ message: "Login successful", user, token });
        } catch (error) {
            console.log(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    updateProfile: async (req, res) => {
        try {
            const { owner_name, phone, email } = req.body;

            if (!owner_name || !phone || !email) {
                return res.status(400).json({ message: "All fields are required" });
            }

            const user = await User.findOne({ where: { id: req.user.id } });

            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }

            user.owner_name = owner_name;
            user.phone = phone;
            user.email = email;

            await user.save();

            return res.status(200).json({ message: "Profile updated successfully", user });
        } catch (error) {
            console.log(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
}

module.exports = usercontroller;