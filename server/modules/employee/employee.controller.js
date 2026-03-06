const Employee = require("./employee.model");
const sequelize = require("../../config/db");
const Attendance = require("../attendance/attendance.model");
const Salary = require("../salary/salary.model");
const EmployeeSalary = require("../employee_salary/employee_salary.model");
const EmployeeOvertimeConfig = require("../employee_overtime_config/employee_overtime_config.model");

const employeeController = {
    create: async (req, res) => {
        try {
            let { 
                company_id, 
                department_id, 
                designation_id, 
                full_name, 
                name, // Flutter compatibility
                phone, 
                mobileNo, // Flutter compatibility
                salary_config_id, 
                monthly_salary,
                salary // Flutter compatibility
            } = req.body;

            // Mapping for Flutter/Form compatibility
            if (!full_name && name) full_name = name;
            if (!phone && mobileNo) phone = mobileNo;
            if (monthly_salary === undefined && salary !== undefined) monthly_salary = salary;

            if (!company_id || !department_id || !designation_id || !full_name || !phone) {
                return res.status(400).json({ message: "Required fields (company, department, designation, name, phone) are missing" });
            }

            const employeeExists = await Employee.findOne({ where: { phone } });
            if (employeeExists) {
                return res.status(400).json({ message: "Employee with this phone already exists" });
            }

            const currentYear = new Date().getFullYear();
            const employeeCount = await Employee.count({ where: { company_id } });
            const employeeNumber = employeeCount + 1;
            const employee_code = `EMP/${currentYear}/${company_id}/${employeeNumber}`;

            // User requested join_date as today's date
            const join_date = new Date();

            const employee = await Employee.create({
                company_id,
                department_id,
                designation_id,
                salary_config_id,
                full_name,
                phone,
                employee_code,
                monthly_salary,
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

            // Handle Flutter field mappings for updates
            if (!updates.full_name && updates.name) updates.full_name = updates.name;
            if (!updates.phone && updates.mobileNo) updates.phone = updates.mobileNo;
            if (updates.monthly_salary === undefined && updates.salary !== undefined) updates.monthly_salary = updates.salary;

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
        const transaction = await sequelize.transaction();
        try {
            const { id } = req.params;
            const employee = await Employee.findByPk(id);

            if (!employee) {
                await transaction.rollback();
                return res.status(404).json({ message: "Employee not found" });
            }

            // Soft delete Employee
            await employee.update({ status: false }, { transaction });

            // Soft delete related records (if they exist)
            if (Attendance) await Attendance.update({ status: false }, { where: { employee_id: id }, transaction });
            if (Salary) await Salary.update({ status: false }, { where: { employee_id: id }, transaction });
            if (EmployeeSalary) await EmployeeSalary.update({ status: false }, { where: { emp_id: id }, transaction });
            if (EmployeeOvertimeConfig) await EmployeeOvertimeConfig.update({ status: false }, { where: { employee_id: id }, transaction });

            await transaction.commit();
            return res.status(200).json({ message: "Employee and all associated records soft deleted successfully" });
        } catch (error) {
            await transaction.rollback();
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = employeeController;
