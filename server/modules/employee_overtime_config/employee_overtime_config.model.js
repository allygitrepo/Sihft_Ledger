const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Employee = require("../employee/employee.model");

const EmployeeOvertimeConfig = sequelize.define("EmployeeOvertimeConfigs",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        employee_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            unique: true,
            references: {
                model: Employee,
                key: 'id'
            }
        },
        overtime_enabled: { type: DataTypes.BOOLEAN, defaultValue: false },
        hourly_rate: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "employee_overtime_configs",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = EmployeeOvertimeConfig;
