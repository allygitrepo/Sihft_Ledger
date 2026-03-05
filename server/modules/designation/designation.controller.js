const Designation = require("./designation.model");

const designationController = {
    create: async (req, res) => {
        try {
            const { department_id, designation_name } = req.body;

            if (!department_id || !designation_name) {
                return res.status(400).json({ message: "Department ID and designation name are required" });
            }

            const designation = await Designation.create({
                department_id,
                designation_name
            });

            return res.status(201).json({ message: "Designation created successfully", designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const { department_id } = req.query;
            const whereClause = department_id ? { department_id } : {};
            const designations = await Designation.findAll({ where: whereClause });
            return res.status(200).json({ designations });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const designation = await Designation.findByPk(id);

            if (!designation) {
                return res.status(404).json({ message: "Designation not found" });
            }

            return res.status(200).json({ designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { designation_name, status } = req.body;

            const designation = await Designation.findByPk(id);

            if (!designation) {
                return res.status(404).json({ message: "Designation not found" });
            }

            await designation.update({
                designation_name,
                status
            });

            return res.status(200).json({ message: "Designation updated successfully", designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const designation = await Designation.findByPk(id);

            if (!designation) {
                return res.status(404).json({ message: "Designation not found" });
            }

            await designation.destroy();
            return res.status(200).json({ message: "Designation deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = designationController;
