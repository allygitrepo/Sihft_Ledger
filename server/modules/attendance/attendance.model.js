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
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "attendance",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Attendance;
