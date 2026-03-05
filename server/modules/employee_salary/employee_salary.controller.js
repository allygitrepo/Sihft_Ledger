const EmployeeSalary = require("./employee_salary.model");

const employeeSalaryController = {
    create: async (req, res) => {
        try {
            const { emp_id, basic_salary, allowances, deductions } = req.body;

            if (!emp_id || !basic_salary) {
                return res.status(400).json({ message: "Employee ID and basic salary are required" });
            }

            const net_salary = parseFloat(basic_salary) + parseFloat(allowances || 0) - parseFloat(deductions || 0);

            const salary = await EmployeeSalary.create({
                emp_id,
                basic_salary,
                allowances,
                deductions,
                net_salary
            });

            return res.status(201).json({ message: "Employee salary configured successfully", salary });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const salaries = await EmployeeSalary.findAll();
            return res.status(200).json({ salaries });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getByEmployeeId: async (req, res) => {
        try {
            const { emp_id } = req.params;
            const salary = await EmployeeSalary.findOne({ where: { emp_id } });

            if (!salary) {
                return res.status(404).json({ message: "Salary configuration not found for this employee" });
            }

            return res.status(200).json({ salary });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { basic_salary, allowances, deductions, status } = req.body;

            const salary = await EmployeeSalary.findByPk(id);

            if (!salary) {
                return res.status(404).json({ message: "Salary configuration not found" });
            }

            const newBasic = basic_salary || salary.basic_salary;
            const newAllowances = allowances !== undefined ? allowances : salary.allowances;
            const newDeductions = deductions !== undefined ? deductions : salary.deductions;
            const net_salary = parseFloat(newBasic) + parseFloat(newAllowances) - parseFloat(newDeductions);

            await salary.update({
                basic_salary: newBasic,
                allowances: newAllowances,
                deductions: newDeductions,
                net_salary,
                status
            });

            return res.status(200).json({ message: "Salary configuration updated successfully", salary });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const salary = await EmployeeSalary.findByPk(id);

            if (!salary) {
                return res.status(404).json({ message: "Salary configuration not found" });
            }

            await salary.destroy();
            return res.status(200).json({ message: "Salary configuration deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = employeeSalaryController;
