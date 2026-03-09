const Salary = require("./salary.model");

const salaryController = {
    saveConfig: async (req, res) => {
        try {
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
                return res.status(400).json({ message: "company_id is required" });
            }

            // Find existing config or create new one
            let config = await Salary.findOne({ where: { company_id } });

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
                return res.status(201).json({ message: "Salary configuration saved successfully", config });
            }
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getConfig: async (req, res) => {
        try {
            const { company_id } = req.params;
            const config = await Salary.findOne({ where: { company_id } });

            if (!config) {
                return res.status(404).json({ message: "Salary configuration not found for this company" });
            }

            return res.status(200).json({ config });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = salaryController;
