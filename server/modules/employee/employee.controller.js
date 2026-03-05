const Employee = require("./employee.model");

const employeeController = {
    create: async (req, res) => {
        try {
            const { company_id, department_id, designation_id, first_name, last_name, phone, email, join_date } = req.body;

            if (!company_id || !department_id || !designation_id || !first_name || !last_name || !phone || !join_date) {
                return res.status(400).json({ message: "Required fields are missing" });
            }

            const employeeExists = await Employee.findOne({ where: { phone } });
            if (employeeExists) {
                return res.status(400).json({ message: "Employee with this phone already exists" });
            }

            const employee = await Employee.create({
                company_id,
                department_id,
                designation_id,
                first_name,
                last_name,
                phone,
                email,
                join_date
            });

            return res.status(201).json({ message: "Employee created successfully", employee });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const { company_id, department_id } = req.query;
            const whereClause = {};
            if (company_id) whereClause.company_id = company_id;
            if (department_id) whereClause.department_id = department_id;

            const employees = await Employee.findAll({ where: whereClause });
            return res.status(200).json({ employees });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const employee = await Employee.findByPk(id);

            if (!employee) {
                return res.status(404).json({ message: "Employee not found" });
            }

            return res.status(200).json({ employee });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const updates = req.body;

            const employee = await Employee.findByPk(id);

            if (!employee) {
                return res.status(404).json({ message: "Employee not found" });
            }

            await employee.update(updates);

            return res.status(200).json({ message: "Employee updated successfully", employee });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const employee = await Employee.findByPk(id);

            if (!employee) {
                return res.status(404).json({ message: "Employee not found" });
            }

            await employee.destroy();
            return res.status(200).json({ message: "Employee deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = employeeController;
