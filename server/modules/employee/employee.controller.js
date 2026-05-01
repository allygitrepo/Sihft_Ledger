const { Op } = require("sequelize");
const Employee = require("./employee.model");
const sequelize = require("../../config/db");
const Attendance = require("../attendance/attendance.model");
const Salary = require("../salary/salary.model");
const EmployeeSalary = require("../employee_salary/employee_salary.model");
const EmployeeOvertimeConfig = require("../employee_overtime_config/employee_overtime_config.model");
const Department = require("../department/department.model");
const Designation = require("../designation/designation.model");
const { Parser } = require("json2csv");
const csv = require("csv-parser");
const fs = require("fs");
const path = require("path");

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

            if (!company_id || !full_name || !phone) {
                return res.status(400).json({ message: "Required fields (company, name, phone) are missing" });
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
            const { company_id, department_id, page = 1, limit = 10, search = '' } = req.query;
            const whereClause = {};
            if (company_id) whereClause.company_id = company_id;
            if (department_id) whereClause.department_id = department_id;

            if (search) {
                whereClause[Op.or] = [
                    { full_name: { [Op.like]: `%${search}%` } },
                    { employee_code: { [Op.like]: `%${search}%` } },
                    { phone: { [Op.like]: `%${search}%` } },
                    { '$Department.department_name$': { [Op.like]: `%${search}%` } },
                    { '$Designation.designation_name$': { [Op.like]: `%${search}%` } }
                ];
            }

            const pageNum = parseInt(page);
            const limitNum = parseInt(limit);
            const offset = (pageNum - 1) * limitNum;

            const { count, rows: employees } = await Employee.findAndCountAll({
                where: whereClause,
                limit: limitNum,
                offset: offset,
                include: [
                    { model: Department, attributes: ['department_name'] },
                    { model: Designation, attributes: ['designation_name'] }
                ]
            });
            return res.status(200).json({ 
                employees,
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
    },

    exportCSV: async (req, res) => {
        try {
            const { company_id } = req.query;
            if (!company_id) return res.status(400).json({ message: "company_id is required" });

            const employees = await Employee.findAll({
                where: { company_id, status: true },
                include: [
                    { model: Department, attributes: ['department_name'] },
                    { model: Designation, attributes: ['designation_name'] }
                ]
            });

            const data = employees.map(emp => ({
                id: emp.id,
                employee_code: emp.employee_code,
                full_name: emp.full_name,
                phone: emp.phone,
                department: emp.Department ? emp.Department.department_name : '',
                designation: emp.Designation ? emp.Designation.designation_name : '',
                monthly_salary: emp.monthly_salary,
                join_date: emp.join_date
            }));

            const fields = ['id', 'employee_code', 'full_name', 'phone', 'department', 'designation', 'monthly_salary', 'join_date'];
            const json2csvParser = new Parser({ fields });
            const csvData = json2csvParser.parse(data);

            res.header('Content-Type', 'text/csv');
            res.attachment(`employees_export_${Date.now()}.csv`);
            return res.send(csvData);
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    importCSV: async (req, res) => {
        const results = [];
        const company_id = req.body.company_id;

        if (!req.file) return res.status(400).json({ message: "CSV file is required" });
        if (!company_id) return res.status(400).json({ message: "company_id is required" });

        let rowCount = 0;
        console.log(`Starting CSV import for company_id: ${company_id}, file: ${req.file.path}`);
        if (!fs.existsSync(req.file.path)) {
            console.error("File does not exist at path:", req.file.path);
            return res.status(500).json({ message: "Uploaded file not found on server" });
        }

        fs.createReadStream(req.file.path)
            .on("error", (err) => {
                console.error("Stream Error:", err);
            })
            .pipe(csv({
                mapHeaders: ({ header }) => {
                    const normalized = header.toLowerCase()
                        .trim()
                        .replace(/employee\s+/g, '')
                        .replace(/\s+/g, '_')
                        .replace(/[^\w]/g, '');
                    console.log(`Mapping header: "${header}" -> "${normalized}"`);
                    return normalized;
                }
            }))
            .on("data", (data) => {
                console.log("Parsed Data Row:", data);
                results.push(data);
            })
            .on("end", async () => {
                console.log(`CSV Parsing complete. Total rows parsed: ${results.length}`);
                const transaction = await sequelize.transaction();
                try {
                    for (const row of results) {
                        rowCount++;
                        let { 
                            id, employee_code, code, 
                            full_name, name, 
                            phone, mobile, mobile_no, mobile_number,
                            department, dept, 
                            designation, position, 
                            monthly_salary, salary,
                            join_date 
                        } = row;

                        // Unified mapping
                        full_name = full_name || name;
                        phone = phone || mobile || mobile_no || mobile_number;
                        employee_code = employee_code || code || id;
                        department = department || dept;
                        designation = designation || position;
                        monthly_salary = monthly_salary || salary;
                        
                        // Clean salary - remove currency symbols, commas, etc.
                        if (monthly_salary) {
                            monthly_salary = parseFloat(monthly_salary.toString().replace(/[^\d.]/g, '')) || 0;
                        } else {
                            monthly_salary = 0;
                        }

                        console.log("Mapped Data:", { id, employee_code, full_name, phone, department, designation, monthly_salary });

                        if (!full_name || !phone) {
                            console.log("Skipping invalid row (missing name or phone):", row);
                            continue;
                        }

                        let department_id = null;
                        let designation_id = null;

                        // Resolve Department
                        if (department && department.trim() !== "") {
                            const [deptObj] = await Department.findOrCreate({
                                where: { department_name: department.trim(), company_id },
                                defaults: { status: true },
                                transaction
                            });
                            department_id = deptObj.id;
                        }

                        // Resolve Designation
                        if (designation && designation.trim() !== "" && department_id) {
                            const [desigObj] = await Designation.findOrCreate({
                                where: { designation_name: designation.trim(), department_id },
                                defaults: { status: true },
                                transaction
                            });
                            designation_id = desigObj.id;
                        }

                        const employeeData = {
                            company_id,
                            department_id,
                            designation_id,
                            full_name,
                            phone,
                            monthly_salary,
                            join_date: (join_date && join_date !== "") ? join_date : new Date().toISOString().split('T')[0],
                            status: true
                        };

                        let targetEmployee = null;

                        // 1. Try finding by internal ID
                        if (id && id !== "" && !isNaN(id)) {
                            targetEmployee = await Employee.findByPk(id, { transaction });
                        }

                        // 2. Try finding by employee_code
                        if (!targetEmployee && employee_code) {
                            targetEmployee = await Employee.findOne({ 
                                where: { employee_code, company_id }, 
                                transaction 
                            });
                        }

                        // 3. Try finding by phone
                        if (!targetEmployee && phone) {
                            targetEmployee = await Employee.findOne({ 
                                where: { phone, company_id }, 
                                transaction 
                            });
                        }

                        if (targetEmployee) {
                            // Update existing
                            await targetEmployee.update(employeeData, { transaction });
                        } else {
                            // Create new
                            // Ensure we have a code if possible
                            const finalData = { ...employeeData };
                            if (employee_code) finalData.employee_code = employee_code;
                            else if (id && isNaN(id)) finalData.employee_code = id; // use string id as code
                            
                            await Employee.create(finalData, { transaction });
                        }
                    }

                    await transaction.commit();
                    fs.unlinkSync(req.file.path); // Clean up temp file
                    return res.status(200).json({ 
                        message: `CSV imported successfully. Processed ${results.length} rows.` 
                    });
                } catch (error) {
                    await transaction.rollback();
                    if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
                    console.error(error);
                    return res.status(500).json({ message: "Internal server error during import" });
                }
            });
    },

    bulkUpsert: async (req, res) => {
        const { company_id, employees } = req.body;
        if (!company_id) return res.status(400).json({ message: "company_id is required" });
        if (!employees || !Array.isArray(employees)) return res.status(400).json({ message: "employees array is required" });

        const transaction = await sequelize.transaction();
        try {
            let processedCount = 0;
            for (const emp of employees) {
                // Map frontend fields to backend fields (handle both camelCase and snake_case)
                const full_name = emp.full_name || emp.name || `${emp.first_name || emp.firstName || ""} ${emp.last_name || emp.lastName || ""}`.trim();
                const phone = emp.phone || emp.mobile_no || emp.mobileNo;
                const employee_code = emp.employee_code || emp.employeeCode;
                const monthly_salary = emp.monthly_salary || emp.salary || emp.salary_original || emp.salaryOriginal;
                const department = emp.department || emp.department_name;
                const designation = emp.designation || emp.position || emp.designation_name;

                if (!full_name || !phone) continue;

                let department_id = emp.department_id || emp.departmentId || null;
                let designation_id = emp.designation_id || emp.designationId || null;

                // Resolve Department
                if (!department_id && department && department.trim() !== "") {
                    const deptName = department.trim();
                    let deptObj = await Department.findOne({
                        where: {
                            company_id,
                            department_name: { [Op.iLike]: deptName }
                        },
                        transaction
                    });
                    
                    if (!deptObj) {
                        deptObj = await Department.create({
                            department_name: deptName,
                            company_id,
                            status: true
                        }, { transaction });
                    } else if (!deptObj.status) {
                        // Re-activate if it was inactive
                        await deptObj.update({ status: true }, { transaction });
                    }
                    department_id = deptObj.id;
                }

                // Resolve Designation
                if (!designation_id && designation && designation.trim() !== "" && department_id) {
                    const desigName = designation.trim();
                    let desigObj = await Designation.findOne({
                        where: {
                            department_id,
                            designation_name: { [Op.iLike]: desigName }
                        },
                        transaction
                    });
                    
                    if (!desigObj) {
                        desigObj = await Designation.create({
                            designation_name: desigName,
                            department_id,
                            status: true
                        }, { transaction });
                    } else if (!desigObj.status) {
                        // Re-activate if it was inactive
                        await desigObj.update({ status: true }, { transaction });
                    }
                    designation_id = desigObj.id;
                }

                const employeeData = {
                    company_id,
                    department_id,
                    designation_id,
                    full_name,
                    phone,
                    employee_code, // Included in core data for updates
                    monthly_salary,
                    join_date: emp.join_date || emp.joinDate || new Date().toISOString().split('T')[0],
                    status: (emp.status === undefined) ? true : emp.status,
                    // Pass specific rates using database snake_case field names
                    hourly_rate: emp.hourly_rate || emp.hourlyRate,
                    daily_rate: emp.daily_rate || emp.dailyRate,
                    employee_type: emp.employee_type || emp.employeeType || 'hourly',
                    overtime_rate: emp.overtime_rate || emp.overtimeRate || 0,
                    overtime_type: emp.overtime_type || emp.overtimeType || 'none'
                };

                let targetEmployee = null;
                // Safely identify real DB IDs (positive integers) vs frontend temporary IDs
                const numericId = parseInt(emp.id);
                if (emp.id && !isNaN(numericId) && numericId < 1000000000) { 
                    targetEmployee = await Employee.findByPk(numericId, { transaction });
                }

                if (!targetEmployee && employee_code) {
                    targetEmployee = await Employee.findOne({ where: { employee_code }, transaction });
                }

                if (!targetEmployee && phone) {
                    targetEmployee = await Employee.findOne({ where: { phone }, transaction });
                }

                if (targetEmployee) {
                    await targetEmployee.update(employeeData, { transaction });
                } else {
                    await Employee.create(employeeData, { transaction });
                }
                processedCount++;
            }

            await transaction.commit();
            return res.status(200).json({ 
                success: true, 
                message: `Successfully processed ${processedCount} employees.` 
            });
        } catch (error) {
            await transaction.rollback();
            console.error("Bulk Upsert Error:", error);
            return res.status(500).json({ message: "Internal server error during bulk update" });
        }
    }
};

module.exports = employeeController;