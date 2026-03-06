const EmployeeOvertimeConfig = require("./employee_overtime_config.model");

const employeeOvertimeConfigController = {
    createOrUpdate: async (req, res) => {
        try {
            const { employee_id, overtime_enabled, hourly_rate } = req.body;

            if (!employee_id) {
                return res.status(400).json({ message: "Employee ID is required" });
            }

            let config = await EmployeeOvertimeConfig.findOne({ where: { employee_id } });

            if (config) {
                await config.update({ overtime_enabled, hourly_rate });
                return res.status(200).json({ message: "Overtime configuration updated successfully", config });
            } else {
                config = await EmployeeOvertimeConfig.create({
                    employee_id,
                    overtime_enabled,
                    hourly_rate
                });
                return res.status(201).json({ message: "Overtime configuration created successfully", config });
            }
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getByEmployeeId: async (req, res) => {
        try {
            const { employee_id } = req.params;
            const config = await EmployeeOvertimeConfig.findOne({ where: { employee_id } });

            if (!config) {
                return res.status(404).json({ message: "Overtime configuration not found for this employee" });
            }

            return res.status(200).json({ config });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const config = await EmployeeOvertimeConfig.findByPk(id);

            if (!config) {
                return res.status(404).json({ message: "Overtime configuration not found" });
            }

            await config.destroy();
            return res.status(200).json({ message: "Overtime configuration deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = employeeOvertimeConfigController;
