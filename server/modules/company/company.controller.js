const Company = require("./company.model");

const companyController = {
    create: async (req, res) => {
        try {
            const { company_name, industry_type, address, company_logo } = req.body;
            const owner_id = req.user.id; // From auth middleware

            if (!company_name || !industry_type) {
                return res.status(400).json({ message: "Company name and industry type are required" });
            }

            const company = await Company.create({
                owner_id,
                company_name,
                industry_type,
                address,
                company_logo
            });

            return res.status(201).json({ message: "Company created successfully", company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const owner_id = req.user.id;
            const companies = await Company.findAll({ where: { owner_id } });
            return res.status(200).json({ companies });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                return res.status(404).json({ message: "Company not found" });
            }

            return res.status(200).json({ company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { company_name, industry_type, address, company_logo, status } = req.body;

            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                return res.status(404).json({ message: "Company not found" });
            }

            await company.update({
                company_name,
                industry_type,
                address,
                company_logo,
                status
            });

            return res.status(200).json({ message: "Company updated successfully", company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        const transaction = await sequelize.transaction();
        try {
            const { id } = req.params;
            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                await transaction.rollback();
                return res.status(404).json({ message: "Company not found" });
            }

            // Soft delete Company
            await company.update({ status: false }, { transaction });

            // 1. Soft delete Departments
            await Department.update({ status: false }, { where: { company_id: id }, transaction });

            // 2. Soft delete Overtime Slots
            await OvertimeSlot.update({ status: false }, { where: { company_id: id }, transaction });

            // Fetch department IDs to delete Designations
            const departments = await Department.findAll({ where: { company_id: id }, attributes: ['id'] });
            const deptIds = departments.map(d => d.id);

            if (deptIds.length > 0) {
                // 3. Soft delete Designations
                await Designation.update({ status: false }, { where: { department_id: deptIds }, transaction });
            }

            // 4. Soft delete Employees and their related records
            const employees = await Employee.findAll({ where: { company_id: id }, attributes: ['id'] });
            const empIds = employees.map(e => e.id);

            if (empIds.length > 0) {
                await Employee.update({ status: false }, { where: { id: empIds }, transaction });
                await Attendance.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await Salary.update({ status: false }, { where: { employee_id: empIds }, transaction });
                await EmployeeSalary.update({ status: false }, { where: { emp_id: empIds }, transaction });
                await EmployeeOvertimeConfig.update({ status: false }, { where: { employee_id: empIds }, transaction });
            }

            await transaction.commit();
            return res.status(200).json({ message: "Company and all related data soft deleted successfully" });
        } catch (error) {
            await transaction.rollback();
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = companyController;
