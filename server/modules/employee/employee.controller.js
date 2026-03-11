const { Op } = require("sequelize");
const Employee = require("./employee.model");
const sequelize = require("../../config/db");
const Attendance = require("../attendance/attendance.model");
const Salary = require("../salary/salary.model");
const EmployeeSalary = require("../employee_salary/employee_salary.model");
const EmployeeOvertimeConfig = require("../employee_overtime_config/employee_overtime_config.model");
const Department = require("../department/department.model");
const Designation = require("../designation/designation.model");

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

            // Validation: Unique name within the same department
            const nameExistsInDept = await Employee.findOne({
                where: {
                    full_name,
                    department_id,
                    status: true // Only check active employees
                }
            });

            if (nameExistsInDept) {
                return res.status(400).json({
                    message: "Employee with same name already exists in this department"
                });
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

            const employees = await Employee.findAll({
                where: whereClause,
                include: [
                    { model: Department, attributes: ['department_name'] },
                    { model: Designation, attributes: ['designation_name'] }
                ]
            });
            return res.status(200).json({ employees });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const employee = await Employee.findByPk(id, {
                include: [
                    { model: Department, attributes: ['department_name'] },
                    { model: Designation, attributes: ['designation_name'] }
                ]
            });

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
            const id = req.params.id || req.body.employee_id;
            if (!id || isNaN(id)) {
                return res.status(400).json({ message: "Valid Employee ID is required" });
            }

            const body = req.body;
            const updates = {};

            // Mapping and filtering for partial updates
            if (body.full_name !== undefined) updates.full_name = body.full_name;
            else if (body.name !== undefined) updates.full_name = body.name;

            if (body.phone !== undefined) updates.phone = body.phone;
            else if (body.mobileNo !== undefined) updates.phone = body.mobileNo;

            if (body.monthly_salary !== undefined) updates.monthly_salary = body.monthly_salary;
            else if (body.salary !== undefined) updates.monthly_salary = body.salary;
            
            if (body.department_id !== undefined && body.department_id !== null) updates.department_id = body.department_id;
            if (body.designation_id !== undefined && body.designation_id !== null) updates.designation_id = body.designation_id;
            if (body.salary_config_id !== undefined) updates.salary_config_id = body.salary_config_id;
            if (body.join_date !== undefined && body.join_date !== null && body.join_date !== '') updates.join_date = body.join_date;
            if (body.status !== undefined && body.status !== null) updates.status = body.status;

            const employee = await Employee.findByPk(id);

            if (!employee) {
                return res.status(404).json({ message: "Employee not found" });
            }

            // Validation: Unique name within the same department (excluding current employee)
            const targetFullName = updates.full_name || employee.full_name;
            const targetDeptId = updates.department_id || employee.department_id;

            const nameExistsInDept = await Employee.findOne({
                where: {
                    full_name: targetFullName,
                    department_id: targetDeptId,
                    status: true,
                    id: { [Op.ne]: id }
                }
            });

            if (nameExistsInDept) {
                return res.status(400).json({
                    message: "Employee with same name already exists in this department"
                });
            }

            await employee.update(updates);

            // Fetch updated employee with associations
            const updatedEmployee = await Employee.findByPk(id, {
                include: [
                    { model: Department, attributes: ['department_name'] },
                    { model: Designation, attributes: ['designation_name'] }
                ]
            });

            return res.status(200).json({ 
                message: "Employee updated successfully", 
                employee: updatedEmployee 
            });
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