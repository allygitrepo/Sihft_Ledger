const Designation = require("./designation.model");
const Department = require("../department/department.model");
const Employee = require("../employee/employee.model");
const Attendance = require("../attendance/attendance.model");
const Salary = require("../salary/salary.model");
const EmployeeSalary = require("../employee_salary/employee_salary.model");
const EmployeeOvertimeConfig = require("../employee_overtime_config/employee_overtime_config.model");
const { Op } = require("sequelize");
const sequelize = require("../../config/db");

const designationController = {
    create: async (req, res) => {
        try {
            const { department_id, designation_name } = req.body;

            if (!department_id || !designation_name) {
                return res.status(400).json({ message: "Department ID and designation name are required" });
            }

            const existing = await Designation.findOne({
                where: {
                    department_id,
                    designation_name: { [Op.iLike]: designation_name.trim() }
                }
            });

            if (existing) {
                if (existing.status) {
                    return res.status(400).json({ message: "Designation already exists in this department" });
                } else {
                    await existing.update({ status: true });
                    return res.status(200).json({ message: "Designation reactivated successfully", designation: existing });
                }
            }

            const designation = await Designation.create({
                department_id,
                designation_name: designation_name.trim()
            });

            return res.status(201).json({ message: "Designation created successfully", designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const { department_id, company_id, page = 1, limit = 10, search = '' } = req.query;
            
            let whereClause = {};
            
            if (department_id) {
                whereClause.department_id = department_id;
            } else if (company_id) {
                // If company_id is provided, find all designations for all departments in that company
                const departments = await Department.findAll({
                    where: { company_id },
                    attributes: ['id']
                });
                const deptIds = departments.map(d => d.id);
                whereClause.department_id = { [Op.in]: deptIds };
            }

            if (search) {
                whereClause.designation_name = { [Op.like]: `%${search}%` };
            }

            const pageNum = parseInt(page);
            const limitNum = parseInt(limit);
            const offset = (pageNum - 1) * limitNum;

            const { count, rows: designations } = await Designation.findAndCountAll({
                where: whereClause,
                limit: limitNum,
                offset: offset,
                order: [['created_at', 'DESC']]
            });

            return res.status(200).json({ 
                designations,
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
            const designation = await Designation.findByPk(id);

            if (!designation) {
                return res.status(404).json({ message: "Designation not found" });
            }

            return res.status(200).json({ designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { designation_name, status, department_id } = req.body;

            const designation = await Designation.findByPk(id);

            if (!designation) {
                return res.status(404).json({ message: "Designation not found" });
            }

            await designation.update({
                designation_name,
                status,
                department_id
            });

            return res.status(200).json({ message: "Designation updated successfully", designation });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        const transaction = await sequelize.transaction();
        try {
            const { id } = req.params;
            const designation = await Designation.findByPk(id);

            if (!designation) {
                await transaction.rollback();
                return res.status(404).json({ message: "Designation not found" });
            }

            // Soft delete Designation
            await designation.update({ status: false }, { transaction });

            // Soft delete Employees in this designation and their related records
            const employees = await Employee.findAll({ where: { designation_id: id }, attributes: ['id'] });
            const empIds = employees.map(e => e.id);

            if (empIds.length > 0) {
                await Employee.update({ status: false }, { where: { id: empIds }, transaction });
                await Attendance.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await Salary.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await EmployeeSalary.update({ status: false }, { where: { emp_id: empIds }, transaction });
                await EmployeeOvertimeConfig.update({ status: false }, { where: { employee_id: empIds }, transaction });
            }

            await transaction.commit();
            return res.status(200).json({ message: "Designation and related employees soft deleted successfully" });
        } catch (error) {
            await transaction.rollback();
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = designationController;
