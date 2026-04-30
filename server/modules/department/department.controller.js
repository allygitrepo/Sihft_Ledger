const Department = require("./department.model");
const Designation = require("../designation/designation.model");
const Employee = require("../employee/employee.model");
const Attendance = require("../attendance/attendance.model");
const Salary = require("../salary/salary.model");
const EmployeeSalary = require("../employee_salary/employee_salary.model");
const EmployeeOvertimeConfig = require("../employee_overtime_config/employee_overtime_config.model");
const sequelize = require("../../config/db");

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
            const { company_id, page = 1, limit = 10, search = '' } = req.query;
            const whereClause = company_id ? { company_id } : {};

            if (search) {
                const { Op } = require("sequelize");
                whereClause.department_name = { [Op.like]: `%${search}%` };
            }

            const pageNum = parseInt(page);
            const limitNum = parseInt(limit);
            const offset = (pageNum - 1) * limitNum;

            const { count, rows: departments } = await Department.findAndCountAll({
                where: whereClause,
                limit: limitNum,
                offset: offset,
                order: [['created_at', 'DESC']]
            });

            return res.status(200).json({ 
                departments,
                totalRecords: count,
                totalPages: Math.ceil(count / limitNum),
                currentPage: pageNum
            });
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
        const transaction = await sequelize.transaction();
        try {
            const { id } = req.params;
            const department = await Department.findByPk(id);

            if (!department) {
                await transaction.rollback();
                return res.status(404).json({ message: "Department not found" });
            }

            // Soft delete Department
            await department.update({ status: false }, { transaction });

            // 1. Soft delete Designations
            await Designation.update({ status: false }, { where: { department_id: id }, transaction });

            // 2. Soft delete Employees and their related records
            const employees = await Employee.findAll({ where: { department_id: id }, attributes: ['id'] });
            const empIds = employees.map(e => e.id);

            if (empIds.length > 0) {
                await Employee.update({ status: false }, { where: { id: empIds }, transaction });
                await Attendance.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await Salary.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await EmployeeSalary.update({ status: false }, { where: { emp_id: empIds }, transaction });
                await EmployeeOvertimeConfig.update({ status: false }, { where: { employee_id: empIds }, transaction });
            }

            await transaction.commit();
            return res.status(200).json({ message: "Department and related data soft deleted successfully" });
        } catch (error) {
            await transaction.rollback();
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = departmentController;
