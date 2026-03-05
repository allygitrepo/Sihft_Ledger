const Department = require("./department.model");

const departmentController = {
    create: async (req, res) => {
        try {
            const { company_id, department_name } = req.body;

            if (!company_id || !department_name) {
                return res.status(400).json({ message: "Company ID and department name are required" });
            }

            const department = await Department.create({
                company_id,
                department_name
            });

            return res.status(201).json({ message: "Department created successfully", department });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const { company_id } = req.query;
            const whereClause = company_id ? { company_id } : {};
            const departments = await Department.findAll({ where: whereClause });
            return res.status(200).json({ departments });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const department = await Department.findOne({ where: { id } });

            if (!department) {
                return res.status(404).json({ message: "Department not found" });
            }

            return res.status(200).json({ department });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { department_name, status } = req.body;

            const department = await Department.findByPk(id);

            if (!department) {
                return res.status(404).json({ message: "Department not found" });
            }

            await department.update({
                department_name,
                status
            });

            return res.status(200).json({ message: "Department updated successfully", department });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const department = await Department.findByPk(id);

            if (!department) {
                return res.status(404).json({ message: "Department not found" });
            }

            await department.destroy();
            return res.status(200).json({ message: "Department deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = departmentController;
