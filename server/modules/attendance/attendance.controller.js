const { Op } = require("sequelize");
const Attendance = require("./attendance.model");
const Employee = require("../employee/employee.model");

const attendanceController = {
    clockIn: async (req, res) => {
        try {
            const { employee_id, date, clock_in } = req.body;

            if (!employee_id || !date || !clock_in) {
                return res.status(400).json({ message: "Required fields are missing" });
            }

            // Check if already clocked in for this date
            const existing = await Attendance.findOne({ where: { employee_id, date } });
            if (existing) {
                return res.status(400).json({ message: "Attendance already marked for this date" });
            }

            const attendance = await Attendance.create({
                employee_id,
                date,
                clock_in,
                attendance_status: 'Present'
            });

            return res.status(201).json({ message: "Clock-in successful", attendance });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    clockOut: async (req, res) => {
        try {
            const { employee_id, date, clock_out } = req.body;

            if (!employee_id || !date || !clock_out) {
                return res.status(400).json({ message: "Required fields are missing" });
            }

            const attendance = await Attendance.findOne({ where: { employee_id, date } });
            if (!attendance) {
                return res.status(404).json({ message: "No clock-in record found for this date" });
            }

            // Calculate total hours (simplified)
            // Note: In real app, use moment or date-fns for time diff
            const startTime = new Date(`${date}T${attendance.clock_in}`);
            const endTime = new Date(`${date}T${clock_out}`);
            const totalHours = (endTime - startTime) / (1000 * 60 * 60);

            await attendance.update({
                clock_out,
                total_hours: totalHours.toFixed(2)
            });

            return res.status(200).json({ message: "Clock-out successful", attendance });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getByEmployee: async (req, res) => {
        try {
            const { employee_id } = req.params;
            const attendance = await Attendance.findAll({ 
                where: { employee_id, status: true },
                order: [['date', 'DESC']]
            });
            return res.status(200).json({ success: true, attendance });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ success: false, message: "Internal server error" });
        }
    },

    updateStatus: async (req, res) => {
        try {
            const { id } = req.params;
            const { status } = req.body;

            const attendance = await Attendance.findByPk(id);
            if (!attendance) {
                return res.status(404).json({ message: "Attendance record not found" });
            }

            await attendance.update({ attendance_status: status });
            return res.status(200).json({ message: "Status updated successfully", attendance });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getByDate: async (req, res) => {
        try {
            const { date } = req.params;
            const { company_id, page = 1, limit = 10, search = '' } = req.query;
            const offset = (page - 1) * limit;
            
            // Build where clause for Employee
            const employeeWhere = { status: true };
            if (company_id) {
                employeeWhere.company_id = company_id;
            }
            if (search) {
                employeeWhere[Op.or] = [
                    { full_name: { [Op.like]: `%${search}%` } },
                    { employee_code: { [Op.like]: `%${search}%` } }
                ];
            }

            const { count, rows } = await Attendance.findAndCountAll({
                where: { date, status: true },
                include: [{
                    model: Employee,
                    attributes: ['id', 'full_name', 'company_id', 'employee_code'],
                    where: employeeWhere,
                    required: true // INNER JOIN to ensure only employees from specified company
                }],
                order: [['createdAt', 'DESC']],
                limit: parseInt(limit),
                offset: parseInt(offset)
            });
            
            return res.status(200).json({ 
                success: true, 
                attendance: rows,
                totalPages: Math.ceil(count / limit),
                currentPage: parseInt(page),
                totalRecords: count
            });
        } catch (error) {
            console.error("Error fetching attendance by date:", error);
            return res.status(500).json({ success: false, message: "Internal server error" });
        }
    },

    mark: async (req, res) => {
        try {
            const {
                employee_id, date, clock_in, clock_out,
                attendance_status, total_hours, work_salary,
                overtime_hours, overtime_salary, total_salary
            } = req.body;

            if (!employee_id || !date) {
                return res.status(400).json({ success: false, message: "Employee ID and Date are required" });
            }

            // Verify employee exists and is active
            const employee = await Employee.findOne({ 
                where: { id: employee_id, status: true } 
            });
            
            if (!employee) {
                return res.status(404).json({ success: false, message: "Employee not found or inactive" });
            }

            // Check if record exists
            let attendance = await Attendance.findOne({ where: { employee_id, date } });

            if (attendance) {
                // Update existing record
                attendance = await attendance.update({
                    clock_in: clock_in || attendance.clock_in,
                    clock_out: clock_out || attendance.clock_out,
                    attendance_status: attendance_status || attendance.attendance_status,
                    total_hours: total_hours !== undefined ? total_hours : attendance.total_hours,
                    work_salary: work_salary !== undefined ? work_salary : attendance.work_salary,
                    overtime_hours: overtime_hours !== undefined ? overtime_hours : attendance.overtime_hours,
                    overtime_salary: overtime_salary !== undefined ? overtime_salary : attendance.overtime_salary,
                    total_salary: total_salary !== undefined ? total_salary : attendance.total_salary,
                    status: true // Ensure status is active
                });
            } else {
                // Create new record
                attendance = await Attendance.create({
                    employee_id,
                    date,
                    clock_in,
                    clock_out,
                    attendance_status: attendance_status || 'Present',
                    total_hours: total_hours || 0,
                    work_salary: work_salary || 0,
                    overtime_hours: overtime_hours || 0,
                    overtime_salary: overtime_salary || 0,
                    total_salary: total_salary || 0,
                    status: true
                });
            }

            return res.status(200).json({ 
                success: true, 
                message: "Attendance marked successfully", 
                attendance 
            });
        } catch (error) {
            console.error("Error marking attendance:", error);
            return res.status(500).json({ 
                success: false, 
                message: "Internal server error",
                error: error.message 
            });
        }
    },

    getAll: async (req, res) => {
        try {
            const { company_id, page = 1, limit = 10, search = '', start_date, end_date, department } = req.query;
            const offset = (page - 1) * limit;
            
            // Build where clause for Employee
            const employeeWhere = { status: true };
            if (company_id) {
                employeeWhere.company_id = company_id;
            }
            if (department && department !== 'All') {
                employeeWhere.department = department;
            }
            if (search) {
                employeeWhere[Op.or] = [
                    { full_name: { [Op.like]: `%${search}%` } },
                    { employee_code: { [Op.like]: `%${search}%` } }
                ];
            }

            // Build where clause for Attendance
            const attendanceWhere = { status: true };
            if (start_date && end_date) {
                attendanceWhere.date = {
                    [Op.between]: [start_date, end_date]
                };
            } else if (start_date) {
                attendanceWhere.date = { [Op.gte]: start_date };
            } else if (end_date) {
                attendanceWhere.date = { [Op.lte]: end_date };
            }

            const { count, rows } = await Attendance.findAndCountAll({
                where: attendanceWhere,
                include: [{
                    model: Employee,
                    attributes: ['id', 'full_name', 'company_id', 'employee_code'],
                    where: employeeWhere,
                    required: true // INNER JOIN to ensure only employees from specified company
                }],
                order: [['date', 'DESC']],
                limit: parseInt(limit),
                offset: parseInt(offset)
            });
            
            return res.status(200).json({ 
                success: true, 
                attendance: rows,
                totalPages: Math.ceil(count / limit),
                currentPage: parseInt(page),
                totalRecords: count
            });
        } catch (error) {
            console.error("Error fetching all attendance:", error);
            return res.status(500).json({ success: false, message: "Internal server error" });
        }
    },

    getMarkedIdsByDate: async (req, res) => {
        try {
            const { date } = req.params;
            const { company_id } = req.query;
            
            // Build where clause for Employee
            const employeeWhere = { status: true };
            if (company_id) {
                employeeWhere.company_id = company_id;
            }

            const attendance = await Attendance.findAll({
                where: { date, status: true },
                attributes: ['employee_id'],
                include: [{
                    model: Employee,
                    attributes: [],
                    where: employeeWhere,
                    required: true
                }]
            });
            
            const markedIds = attendance.map(a => a.employee_id.toString());
            
            return res.status(200).json({ success: true, markedIds });
        } catch (error) {
            console.error("Error fetching marked ids by date:", error);
            return res.status(500).json({ success: false, message: "Internal server error" });
        }
    }
};

module.exports = attendanceController;
