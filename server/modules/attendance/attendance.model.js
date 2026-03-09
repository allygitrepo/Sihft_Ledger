const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Employee = require("../employee/employee.model");

const Attendance = sequelize.define("Attendance",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        employee_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Employee,
                key: 'id'
            }
        },
        date: { type: DataTypes.DATEONLY, allowNull: false },
        clock_in: { type: DataTypes.TIME, allowNull: true },
        clock_out: { type: DataTypes.TIME, allowNull: true },
        attendance_status: { type: DataTypes.ENUM('Present', 'Absent', 'Leave', 'Half-day'), defaultValue: 'Present' },
        late_minutes: { type: DataTypes.INTEGER, defaultValue: 0 },
        total_hours: { type: DataTypes.DECIMAL(4, 2), defaultValue: 0.00 },
        work_salary: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        overtime_hours: { type: DataTypes.DECIMAL(4, 2), defaultValue: 0.00 },
        overtime_salary: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        total_salary: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "attendance",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

// Associations
Attendance.belongsTo(Employee, { foreignKey: 'employee_id' });
Employee.hasMany(Attendance, { foreignKey: 'employee_id' });

module.exports = Attendance;
