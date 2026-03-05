const Attendance = require("./attendance.model");

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
            const attendance = await Attendance.findAll({ where: { employee_id } });
            return res.status(200).json({ attendance });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
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
    }
};

module.exports = attendanceController;
