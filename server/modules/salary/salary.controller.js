const Salary = require("./salary.model");
const OvertimeSlot = require("../overtime_slots/overtime_slots.model");

const salaryController = {
    saveConfig: async (req, res) => {
        try {
            console.log("[SalaryController] saveConfig request body:", req.body);
            const {
                company_id,
                salary_calculation_method,
                hours_per_day,
                days_per_month,
                salary_input_type,
                overtime_enabled,
                overtime_type,
                default_overtime_rate
            } = req.body;

            if (!company_id) {
                console.error("[SalaryController] saveConfig: company_id is missing");
                return res.status(400).json({ message: "company_id is required" });
            }

            // Find existing config or create new one
            let config = await Salary.findOne({ where: { company_id } });
            console.log("[SalaryController] Existing config found:", config ? "Yes" : "No");

            if (config) {
                await config.update({
                    salary_calculation_method,
                    hours_per_day,
                    days_per_month,
                    salary_input_type,
                    overtime_enabled,
                    overtime_type,
                    default_overtime_rate
                });
                console.log("[SalaryController] Config updated successfully");
                return res.status(200).json({ message: "Salary configuration updated successfully", config });
            } else {
                config = await Salary.create({
                    company_id,
                    salary_calculation_method,
                    hours_per_day,
                    days_per_month,
                    salary_input_type,
                    overtime_enabled,
                    overtime_type,
                    default_overtime_rate
                });
                console.log("[SalaryController] Config created successfully");
                return res.status(201).json({ message: "Salary configuration saved successfully", config });
            }
        } catch (error) {
            console.error("[SalaryController] Error in saveConfig:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getConfig: async (req, res) => {
        try {
            const { company_id } = req.params;
            console.log("[SalaryController] getConfig for company_id:", company_id);

            const config = await Salary.findOne({ where: { company_id } });
            console.log("[SalaryController] Config found for", company_id, ":", config ? "Yes" : "No");

            if (!config) {
                return res.status(404).json({ message: "Salary configuration not found for this company" });
            }

            // Also fetch overtime slots for this company
            const overtime_slots = await OvertimeSlot.findAll({ where: { company_id } });
            console.log("[SalaryController] Found", overtime_slots.length, "overtime slots");

            // Convert Sequelize instance to plain object to add properties
            const configJson = config.toJSON();
            configJson.overtime_slots = overtime_slots;

            return res.status(200).json({ config: configJson });
        } catch (error) {
            console.error("[SalaryController] Error in getConfig:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = salaryController;
