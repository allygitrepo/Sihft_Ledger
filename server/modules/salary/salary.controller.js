const Salary = require("./salary.model");

const salaryController = {
    generateSalary: async (req, res) => {
        try {
            const { employee_id, month, basic_pay, overtime_pay, bonus, deductions, present_days, absent_days, total_days, overtime_hours } = req.body;

            if (!employee_id || !month || basic_pay === undefined) {
                return res.status(400).json({ message: "Essential fields for generation are missing" });
            }

            const net_pay = parseFloat(basic_pay) + parseFloat(overtime_pay || 0) + parseFloat(bonus || 0) - parseFloat(deductions || 0);

            let salary = await Salary.findOne({ where: { employee_id, month } });

            if (salary) {
                await salary.update({
                    total_days,
                    present_days,
                    absent_days,
                    overtime_hours,
                    basic_pay,
                    overtime_pay,
                    bonus,
                    deductions,
                    net_pay
                });
                return res.status(200).json({ message: "Salary recalculated and updated successfully", salary });
            } else {
                salary = await Salary.create({
                    employee_id,
                    month,
                    total_days,
                    present_days,
                    absent_days,
                    overtime_hours,
                    basic_pay,
                    overtime_pay,
                    bonus,
                    deductions,
                    net_pay
                });
                return res.status(201).json({ message: "Salary generated and saved successfully", salary });
            }
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getSalariesByMonth: async (req, res) => {
        try {
            const { month } = req.query;
            const whereClause = month ? { month } : {};
            const salaries = await Salary.findAll({ where: whereClause });
            return res.status(200).json({ salaries });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getEmployeeSalaryHistory: async (req, res) => {
        try {
            const { employee_id } = req.params;
            const history = await Salary.findAll({ where: { employee_id }, order: [['month', 'DESC']] });
            return res.status(200).json({ history });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    markAsPaid: async (req, res) => {
        try {
            const { id } = req.params;
            const salary = await Salary.findByPk(id);

            if (!salary) {
                return res.status(404).json({ message: "Salary record not found" });
            }

            await salary.update({ payment_status: 'Paid' });
            return res.status(200).json({ message: "Salary marked as paid", salary });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = salaryController;
