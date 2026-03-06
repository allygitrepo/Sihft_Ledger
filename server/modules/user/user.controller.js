const User = require("./user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const usercontroller = {
    // ============ Register ============

    register: async (req, res) => {
        try {
            const { owner_name, phone, email, password } = req.body;

            if (!owner_name || !phone || !password) {
                return res.status(400).json({ message: "All fields are required" });
            }
            const userExists = await User.findOne({ where: { phone } });

            if (userExists) {
                return res.status(400).json({ message: "User already exists" });
            }

            const hashPass = await bcrypt.hash(password, 10);
            const user = await User.create({
                owner_name,
                phone,
                email,
                password: hashPass
            });

            return res.status(201).json({ message: "User registered successfully", user });
        } catch (error) {
            console.log(error);
            return res.status(500).json({ message: "Internal server error" });
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